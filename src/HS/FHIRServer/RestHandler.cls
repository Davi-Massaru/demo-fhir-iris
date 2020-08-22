Include (HS.FHIRServer, Ensemble)

/// FHIR REST Handler
Class HS.FHIRServer.RestHandler Extends %CSP.REST
{

/// This parameter influences the CORS support. The default is an empty string meaning 'not specified'.
/// If set to true (1) then CORS processing is ON. If set to false (0) then CORS processing is OFF.
/// If left unset "" then the decision to process CORS is delegated to the setting on the URL map route.
Parameter HandleCorsRequest As %Integer = 1;

Parameter DefaultContentType As %String = "JSON";

/// DefaultContentType specifies the content type to use when no
/// content type is specified in the incoming request.  The FHIR
/// spec at http://www.hl7.org/fhir/STU3/http.html#mime-type is
/// clear about defaulting if no acceptable format is specified via
/// content negotiation:  "If neither the accept header nor the 
/// _format parameter are specified, the MIME-type of the content 
/// returned by the server is undefined and may vary."
/// Per the FHIR spec, "FHIR uses UTF-8 for all request and response bodies."
/// (http://www.hl7.org/fhir/http.html#mime-type) Setting this parameter
/// to 1 (the default in %CSP.Page is 0) will cause CSP to convert the request
/// content to internal format before passing it to this handler (The equivalent
/// of doing $ZCVT(val, "I", "UTF8") on the request content).
Parameter CONVERTINPUTSTREAM = 1;

/// Per the FHIR spec, "requests and responses SHALL explicitly set the
/// character encoding to UTF-8 using the charset parameter of the MIME-type
/// in the Content-Type header" (http://www.hl7.org/fhir/http.html#mime-type).
/// However what we have observed working with various FHIR clients is that
/// clients sometimes include a Content-Type header in a request with no
/// charset parameter. Setting the value of this key to 1 in the Configuration
/// Registry in this namespace will cause a missing Content-Type charset to be
/// ignored rather than rejected. A non-null charset that is not "utf8" or
/// "utf-8" (case-insensitive) will still be rejected.
Parameter IGNOREMISSINGCHARSETKEY = "\FHIR\IgnoreMissingContentTypeCharset";

/// The UrlMap describes how incoming REST URL requests and their parameters get
/// dispatched to each of the handler-methods in this class.
XData UrlMap
{
<Routes>

<Map Prefix="/customrestapi*" Forward="Vaccine.api.dispath.Dispatch"/>

<Route Url="/(.*)"  					Method="GET" 		Call="processRequest"/>
<Route Url="/(.*)"  					Method="POST" 		Call="processRequest"/>
<Route Url="/(.*)"  					Method="PUT" 		Call="processRequest"/>
<Route Url="/(.*)"  					Method="DELETE" 	Call="processRequest"/>
<Route Url="/(.*)"  					Method="PATCH" 		Call="processRequest"/>
<Route Url="/(.*)"  					Method="HEAD" 		Call="processRequest"/>
</Routes>
}

ClassMethod Page(skipheader As %Boolean = 1) As %Status
{
	Do ..EnsureRESTConfig()
	Set tSC = ##super(skipheader)
	kill %hsrestconfig
	return tSC
}

/// Called by %REST base class when an OPTIONS request is received.
/// This method provides handling of the options request.
/// Note carefully: If authentication is required then this method will be
/// called before login and as such will have only limited privileges
ClassMethod OnHandleOptionsRequest(pUrl As %String) As %Status
{
	Set tSC = ##super(pUrl)
	
	// FHIR No longer supports OPTIONS for accssing CapabilitiesStatements
	// "However as of STU3, this method is deprecated, and will be removed in
	// a future version. Using OPTIONS like this is not conformant with HTTP, 
	// and creates challenges for cross-origin resource sharing support."

#;	if (pUrl = "/") && $$$ISOK(tSC) {
#;		Set tSC = ..processRequest("/metadata")
#;	}
	Quit tSC
}

/// 
/// Process an inbound request.  This hands off the incoming request to the business service.
/// 
ClassMethod processRequest(pRequestPath As %String) As %Status
{
	#dim %request As %CSP.Request
	#dim %hsrestconfig as HS.Util.RESTCSPConfig
	
	set appKey = $$$AppKeyFromApp(%request.AppMatch)
	set serviceConfig = ##class(HS.FHIRServer.API.InteractionsStrategy).GetServiceConfigDataForEndpoint(appKey)
	
	// Do some Logging
	Set tMethodDesc = "["_$classname()_":"_$get(%methodname)_"]"
	Do ..LogCSPRequest(tMethodDesc, 1)

	// The only unauthenticated interaction allowed is metadata
	if ( '..IsRequestAuthenticated() && (pRequestPath '= "metadata")) {
		Set isNoAuthAllowed = (serviceConfig.DebugMode \ $$$FHIRDebugAllowNoAuthCheck # 2)
		if 'isNoAuthAllowed {
			Set %response.Status = ..#HTTP401UNAUTHORIZED
			Return $$$OK
		}
	} 
	// This flag tells the Outcome processor to emit a stack trace.  We don't want
	// to do this in production.
	Set %FHIRDebugIncludeTracebacks = (serviceConfig.DebugMode \ $$$FHIRDebugIncludeTracebacks # 2)

	// Next Build a Request object from the Http Request and parsed URL
	#dim tRequest As HS.FHIRServer.API.Data.Request = ##class(HS.FHIRServer.API.Data.Request).%New()
	#dim tResponse As HS.FHIRServer.API.Data.Response = ""
	#dim outputStream as %Stream.Object = ##class(HS.FHIRServer.Util.DeviceStream).%New()

	
	// Initialize the FHIRRequest
	Set tRequest.RequestPath = pRequestPath
	// Populate information from the Http request
	Do ..marshallRequestFromHttp(tRequest)
	
	// If we have an OAuth client configured and an OAuth Token
	// Include them in the request 
	Set clientName = %hsrestconfig.OAuthClientName
	if clientName '= "" {
		Set accessToken = ##class(%SYS.OAuth2.AccessToken).GetAccessTokenFromRequest(.tSC)
		If accessToken '= "" {
			Do tRequest.AdditionalInfo.SetAt(accessToken, "USER:OAuthToken")
			Do tRequest.AdditionalInfo.SetAt(clientName, "USER:OAuthClient")
		}
	}
	
	if (%hsrestconfig.ServiceConfigName '= "") {
		// Take the alternate path through a Production
		return ..dispatchToEnsemble(tRequest)	
	}
	
	Try {
		// Process Protocol rules for Accept and Content-Type Headers.
		// Check Accept (Output) first, to cover the case where Accept
		// is valid but Content-Type is not, so we can know the format
		// for the OperationOutcome for the invalid Content-Type.
		Set tRequest.ResponseFormatCode =  ..determineOutputFormatCode()
		Set tRequest.RequestFormatCode =  ..determineInputFormatCode()
		$$$FSLog("RequestType: "_tRequest.RequestFormatCode_", ResponseType: "_tRequest.ResponseFormatCode)
		
		Set fhirService = ##class(HS.FHIRServer.Service).EnsureInstance(appKey)

		// We have a well formed Request now.  We send it either to the FHIR Service or to Ensemble
		Set tStatus = $$$OK
		// Dispatch Directly to a FHIR Service
		//$$$FSLog("Call Service;  Interaction="_tRequest.Interaction_", Type="_tRequest.Type_", User: "_$Username_", Roles: "_$Roles)
		//$$$FSLog("Content: "_%request.Content_", code: "_tRequest.RequestFormatCode_ " -> "_tRequest.ResponseFormatCode)

		// Convert any payload into a JSON object
		If $IsObject(%request.Content) {
			Set tRequest.Json = fhirService.StreamToJSON(%request.Content, tRequest.RequestFormatCode)
		}			
		Do fhirService.DispatchRequest(tRequest, .tResponse)
		$$$FSLog("Response Status: "_tResponse.Status_ ", Json: "_$S(tResponse.Json="":"<None>", 1:tResponse.Json.resourceType))
		
		// Process the FHIR response back to the calling REST client
		Do ..marshallResponseHeaders(tResponse)
		
		Do ..WriteServiceResponse(tResponse, fhirService, outputStream, .%response)
		
	} Catch (tEx) {
		Set tStatus = tEx.AsStatus()
		Set outcome = ##class(HS.FHIRServer.Util.Outcome).CreateFromStatus(tStatus, .httpStatus)
		Set %response.Status = httpStatus
		if $Get(tResponse)="" {
			Set tResponse = tRequest.NewResponse()
			Set tResponse.ResponseFormatCode = tRequest.ResponseFormatCode
			Set tResponse.IsPrettyOut = 1
			Set tResponse.Json = outcome
		}
		Do ..WriteServiceResponse(tResponse, $get(fhirService), outputStream, .%response)
	}
	
	Do ..LogCSPResponse(tMethodDesc, 1)
	Return $$$OK
}

ClassMethod WriteErrorResponse(json As %DynamicObject, pFHIRResponse As HS.FHIRServer.API.Data.Response, fhirService As HS.FHIRServer.Service, pOutStream As %Stream.Object, ByRef pMimeObj)
{
	// NOTE: The status may be returned even before the service was invoked, so we handle a missing response here
	if $IsObject(pFHIRResponse) {
		Set pFHIRResponse.Json = json
		Do ..WriteServiceResponse(pFHIRResponse, fhirService, pOutStream, pMimeObj)
	} else {
		// We can't determine the Mime Types, then we will force a JSON response.
		do ..WriteResponse(json, $$$FHIRContentCodeJSON, 1, fhirService, pOutStream, pMimeObj)
	}
}

ClassMethod WriteServiceResponse(pFHIRResponse As HS.FHIRServer.API.Data.Response, fhirService As HS.FHIRServer.Service, pOutStream As %Stream.Object, ByRef pMimeObj)
{
	do ..WriteResponse(pFHIRResponse.Json, pFHIRResponse.ResponseFormatCode, pFHIRResponse.IsPrettyOut, fhirService, pOutStream, pMimeObj)
}

ClassMethod WriteResponse(json As %DynamicObject, pResponseFormatCode As %String, isPretty As %Boolean, fhirService As HS.FHIRServer.Service, pOutStream As %Stream.Object, ByRef pMimeObj)
{
	// PreCondition: The HttpStatus has already been set into the %response
	if $IsObject(json) {
		// Set the Mime Headers in the response if there is content
		Do ..GetResponseMimeType(pResponseFormatCode , .pMimeObj)
		
		if isPretty {
			Set indent = "  "
			set lineEnd = $C(13,10)
		} else {
			Set indent = ""
			set lineEnd = ""
		}
		// Write the content
		If (pResponseFormatCode = $$$FHIRContentCodeXML) {
			//If the service is unavailable (threw a 503), we need another way to get the schema
			if fhirService = "" {
				set strategy = ##class(HS.FHIRServer.API.InteractionsStrategy).GetStrategyForEndpoint($$$AppKeyFromApp(%request.AppMatch))
				Set schema = strategy.schema
			}
			else {
				set schema = fhirService.Schema
			}
			// Output as XML
			Do ##class(HS.FHIRServer.Util.JSONToXML).JSONToXML(json, .pOutStream, schema, indent, lineEnd)
		} Else {
			// Output as JSON
			Do ##class(HS.FHIRServer.Util.JsonHelper).ToJSONStream(json,.pOutStream, indent, lineEnd)
		}
	}
}

/// @API
/// Writes any returned content from the Response object to a stream, converting
/// into the requested content format (json or xml).
/// Sets the ContentType and CharSet properties in the specified'toObject' 
ClassMethod GetResponseMimeType(pResponseFormatCode As %String, ByRef toObject)
{
	If (pResponseFormatCode = $$$FHIRContentCodeXML) {
		// Output as XML
		Set toObject.ContentType = "application/fhir+xml"
		Set toObject.CharSet = "UTF-8"
	} Else {
		// Output as JSON
		Set toObject.ContentType = "application/fhir+json"
		Set toObject.CharSet = "UTF-8"
	}
}

ClassMethod IsRequestAuthenticated()
{
	return $USERNAME '= "UnknownUser"
}

/// 
/// Marshall the incoming FHIR REST request into a message ready for dispatch to the FHIR business service
/// 
ClassMethod marshallRequestFromHttp(pRequest As HS.FHIRServer.API.Data.Request) [ Internal ]
{
	#dim tStatus As %Status = $$$OK
		
	#dim tKey As %String
	#dim tSubKey As %String
	#dim tItem As %String
	#dim tHeader As %String
	#dim %request As %CSP.Request

	Set pRequest.RequestMethod = %request.Method
	// %request.Application is the request base URL including the URLPrefix, if there is one.
	Set tBaseURL = %request.Application
	// Strip trailing '/'
	If $Extract(tBaseURL, *)="/" Set tBaseURL = $Extract(tBaseURL, 1, *-1)

	// TODO:  Note - If the request came through a proxy, we should build the URL that goes to the proxy.
	Set pRequest.BaseURL = %request.CgiEnvs("REQUEST_SCHEME")_"://"_%request.CgiEnvs("HTTP_HOST")_tBaseURL
	// DEVNOTE: The QueryString property of the %request object does not properly escape unicode characters, so we must
	// build the string using %request.Data (Bug: IF-728)
	Set pRequest.QueryString = ##class(HS.FHIRServer.API.Data.QueryParameters).CreateFromCSPRequest(%request).AsString()

	// So far, only DSTU2 uses Conformance, all others (STU3 for now) use Capability
	// The Session Application is the CSP App Key (the trailing slash is removed)
	Set pRequest.SessionApplication = $$$AppKeyFromApp(%request.AppMatch)
	
	// Copy in HTTP header values used in the FHIR API
	Set pRequest.IfNoneMatch = $Get(%request.CgiEnvs("HTTP_IF_NONE_MATCH"))
	Set pRequest.IfModifiedSince = $Get(%request.CgiEnvs("HTTP_IF_MODIFIED_SINCE"))
	Set pRequest.IfMatch = $Get(%request.CgiEnvs("HTTP_IF_MATCH"))
	Set pRequest.IfNoneExist = $Get(%request.CgiEnvs("HTTP_IF_NONE_EXIST"))
	Set pRequest.Prefer = $Get(%request.CgiEnvs("HTTP_PREFER"))
	
	Do pRequest.AdditionalInfo.SetAt(%request.CgiEnvs("REMOTE_ADDR"), "ClientAddr")
	Do pRequest.AdditionalInfo.SetAt(%request.Secure, "Secure")
	Do pRequest.AdditionalInfo.SetAt(%session.SessionId, "CSPSessionId")
	
	// For compatability, copy all HTTP_ headers into the AdditionalInfo section of the request
	Set tKey = ""
	For {
		Set tKey = $ORDER(%request.CgiEnvs(tKey))
		Quit:tKey=""
		
		If tKey?1"HTTP_"1.E {
			// Determine the proper header name (will be all caps unfortunately)
			Set tHeader = $PIECE(tKey,"HTTP_",2,*)
			
			// Copy the HTTP headers
			Do pRequest.AdditionalInfo.SetAt(%request.CgiEnvs(tKey), "HEADER:"_tHeader)
		}
	}
}

ClassMethod dispatchToEnsemble(pRequest As HS.FHIRServer.API.Data.Request) As %Status
{
	#dim %hsrestconfig as HS.Util.RESTCSPConfig
	Set tStatus = $$$OK
		
	Set inputQuickStream = ""
	Set outputQuickStream = ""
	Set inputQuickStreamId = ""
	Set outputStream = ##class(HS.FHIRServer.Util.DeviceStream).%New()	
	try {
		// Copy the HTTP body (if any) to the Ensemble-bound message
		Set tServiceConfigName = %hsrestconfig.ServiceConfigName

		// Process Protocol rules for Accept and Content-Type Headers.
		// Check Accept (Output) first, to cover the case where Accept
		// is valid but Content-Type is not, so we can know the format
		// for the OperationOutcome for the invalid Content-Type.
		Set pRequest.ResponseFormatCode =  ..determineOutputFormatCode()
		Set pRequest.RequestFormatCode =  ..determineInputFormatCode()
		$$$FSLog("RequestType: "_pRequest.RequestFormatCode_", ResponseType: "_pRequest.ResponseFormatCode)

		// Put any uploaded content into a QuickStream
		If $IsObject(%request.Content) {
			Set inputQuickStream = ##class(HS.SDA3.QuickStream).%New()
			Set inputQuickStreamId = inputQuickStream.%Id()
			$$$ThrowOnError( inputQuickStream.CopyFrom(%request.Content) )
		}
		$$$FSLog("Processing via Interop Service: "_tServiceConfigName)
		// Dispatch to the FHIR business service
		#dim ensRequest as HS.FHIRServer.Interop.Request = ##class(HS.FHIRServer.Interop.Request).%New()
		#dim ensResponse as HS.FHIRServer.Interop.Response
		
		// Invoke the Service
		Set ensRequest.Request = pRequest
		Set ensRequest.QuickStreamId = inputQuickStreamId
	
		// An exception is thrown if the FHIR Request was not processed.
		If $G($$$EnsRuntime("Name"))="" {
			#; Production not running.
			$$$ThrowFHIR($$$HttpOnlyResponse(503))
		}
		
		// Construct the business service
		$$$ThrowOnError( ##class(Ens.Director).CreateBusinessService(tServiceConfigName, .tService) )

		// Now, process it
		$$$ThrowOnError( tService.ProcessInput(ensRequest, .ensResponse) )
		
		// Set up the HttpResponse from the FHIR Response
		Do ..marshallResponseHeaders(ensResponse.Response)
		
		// If there is any content, pass it back directly
		if ( ensResponse.QuickStreamId '= "" ) {
			Set %response.ContentType = ensResponse.ContentType
			Set %response.CharSet = ensResponse.CharSet
			Set outputQuickStream = ##class(HS.SDA3.QuickStream).%OpenId(ensResponse.QuickStreamId)
			Do outputStream.CopyFrom(outputQuickStream)
		
		}
	} catch tEx {
		Set tStatus = tEx.AsStatus()
		Set outcome = ##class(HS.FHIRServer.Util.Outcome).CreateFromStatus(tStatus, .httpStatus)
		Set %response.Status = httpStatus
		If ($IsObject($Get(pRequest))&&(pRequest.ResponseFormatCode'="")) {
			Do ..WriteResponse(outcome, pRequest.ResponseFormatCode, 1, "", outputStream, %response)
		} Else {
			Do ..WriteErrorResponse(outcome, "", "", outputStream, %response)
		}
	}
	// ---- FINALLY ----
	// Clear out the request QuickStream
	if ( inputQuickStream '= "" ) {
		Do inputQuickStream.Clear(1)
		kill inputQuickStream
	}

	// Clear out the response QuickStream
	if ( outputQuickStream '= "" ) {
		Do outputQuickStream.Clear(1)
		kill outputQuickStream
	}

	// Return the status
	Return $$$OK
}

/// 
/// Marshall a raw HS.FHIRServer.API.Data.Response message out onto the wire
/// 
ClassMethod marshallResponseHeaders(pResponse As HS.FHIRServer.API.Data.Response) [ Internal ]
{
	#dim %response As %CSP.Response

	// Default the response to OK
	Set %response.Status = $Select(pResponse.Status="":200, 1:pResponse.Status)
	
	if pResponse.Location '= "" {
		Do %response.SetHeader( "Location", pResponse.Location)
		Do %response.SetHeader( "Content-Location", pResponse.Location)
	}
	If pResponse.ETag '= "" {
		Do %response.SetHeader( "ETag", pResponse.ETag)
	}
	If pResponse.LastModified '= "" {
		Do %response.SetHeader( "Last-Modified", pResponse.LastModified)
	}
	
	Quit
}

/// 
/// Return the requested content format codes for the POSTed input data. The format codes
/// are $$$FHIRContentCodeXML and $$$FHIRContentCodeJSON.  The format of the input data (if any) is determined by the Content-Type
/// header.  This method analyzes the various acceptable Mime-Types and ensures that the CharSet is
/// also proper. If the requested type is not supported, a 415 is returned for all FHIR versions.  (Note: before R4, the return code was unspecified in the
/// FHIR Spec).  The spec says "... and 415 Unsupported Media Type when the client posts a format that is not supported to the server."
/// <br>
ClassMethod determineInputFormatCode(pRequest As HS.FHIRServer.API.Data.Request) As %String
{
	Set tRequestContentType = %request.ContentType
	Set inputFormatCode = ""
	// If the request has a Content-Type header, then also validate its charset parameter.
	// CSP parses it out of the Content-Type header and into %request.CharSet, if present.
	// Since Content-Type is meaningless on a GET request, we skip this check on a GET
	If ((tRequestContentType '= "") && (%request.Method '= "GET")) {
		Set tContentTypeCharset = $ZCVT(%request.CharSet,"L")
		// Error if the content type charset is missing, UNLESS the system is configured to ignore a missing charset.
		// The default behavior is that a missing charset will NOT be ignored (ie, the request rejected with an error).
		If (tContentTypeCharset="") {
			// ALWAYS ignore a missing charset, it is too likely that a client app will not specify it but uses UTF-8
		}
		ElseIf (tContentTypeCharset '= "utf8") && (tContentTypeCharset '= "utf-8") {
			// This will cause a 415 Unsupported Media Type to be returned in the HTTP response.
			$$$ThrowFHIR($$$HSFHIRErrInvalidContentCharset, tRequestContentType_";"_tContentTypeCharset, $$$OutcomeInvalid(415))
		}
		Set inputFormatCode = ..GetFormatForContentType(tRequestContentType)

		If inputFormatCode="" {
			// This will cause a 415 Unsupported Media Type to be returned in the HTTP response.
			$$$ThrowFHIR($$$HSFHIRErrInvalidContentType, tRequestContentType, $$$OutcomeInvalid(415))
		}
	}
	return inputFormatCode
}

/// Return the Format Code ($$$FHIRContentCodeJSON or $$$FHIRContentCodeXML) for
/// the output data.
/// 1. check for '_format' parameter.  If present, use that.
/// 2. check the "Accept" header.  If present, use that.  
/// Require charset is utf-8 (if present).  Allow non-presence of charset spec.
/// NOTE: The STU3 spec was stricter, but R4 removes the strictness because it was a pain.
///       we will follow the R4 spec for R3.
/// 3. Use the default (from the configuration)
ClassMethod determineOutputFormatCode(pRequest As HS.FHIRServer.API.Data.Request) As %String
{
	Set tRequestFormat = %request.Get("_format")
	// A valid _format parameter value overrides the HTTP_ACCEPT header value, so check _format
	// first. The _format parameter will be either from the request URL or from the search URL
	// found in the Content when Content-Type is application/x-www-form-urlencoded.
	If tRequestFormat'="" {
		Set tAccept = ..GetFormatForParameter(tRequestFormat)
		if tAccept '= "" {
			return tAccept
		}
		// This will cause a 406 Not Acceptable to be returned in the HTTP response.
		$$$ThrowFHIR($$$HSFHIRErrInvalidParameterValue, "_format", tRequestFormat, $$$OutcomeInvalid(406))
	}
	// Determine whether ACCEPT_CHARSET allows utf-8
	// The variable tAcceptCharsetHeader will be "" unless
	// the header accepts utf8.
	// Otherwise, it will contain the actual header value for error reporting.
	// This value can be overridden on a Accept header.
	Set tAcceptCharsetHeader = $GET(%request.CgiEnvs("HTTP_ACCEPT_CHARSET"))
	If (tAcceptCharsetHeader '= "") {
		Set tFound = 0
		For tJ=1:1:$L(tAcceptCharsetHeader,",") {
			Set tOneAcceptCharset = $P(tAcceptCharsetHeader,",",tJ)
			// Could have a q param, separated by ";"
			Set tOneAcceptCharset = $P(tOneAcceptCharset,";")
			Set tOneAcceptCharset = $ZSTRIP(tOneAcceptCharset, "<>W")
			Set tOneAcceptCharset = $ZCVT(tOneAcceptCharset,"L")
			If (tOneAcceptCharset="utf8")||(tOneAcceptCharset="utf-8") { 
				Set tAcceptCharsetHeader=""
				Quit
			}
		}
	}
	if tAcceptCharsetHeader '= "" {
		// We encountered only invalid charsets in ACCEPT_CHARSET header
		// This will cause a 406 Not Acceptable to be returned in the HTTP response.
		$$$ThrowFHIR($$$HSFHIRErrInvalidAcceptCharset, tAcceptCharsetHeader, $$$OutcomeInvalid(406))
	}
	
	// Now check the Accept Header value(s)
	Set tAcceptHeader = $GET(%request.CgiEnvs("HTTP_ACCEPT"))
	If tAcceptHeader '= "*/*" {
		// Check each value for one we can satisfy.  We scan all for a valid one
		// before reporting any errors
		Set badCharset = "" // Text of a non-utf8 charset found
		Set badAccept = 1	// True if no supported mime types are specified
		Set tAccept = ""
		For tIndex = 1:1:$L(tAcceptHeader,",") {
			Set tAcceptMime = ..getValueAndCharset( $P(tAcceptHeader,",",tIndex), .tAcceptCharset)
			// Get the value of the charset param (if present), then if we end up using the current content type,
			// but the charset is non-null and *not* utf-8, return an error.
			// If we encounter a valid FHIR mime type, it must either have a valid charset
			// value or no charset value.
			If (tAcceptMime'="") {
				Set tAccept = ..GetFormatForAccept(tAcceptMime)
				if tAccept '= "" {
					If (tAcceptCharset '= "") {
						if (tAcceptCharset = "utf-8") || (tAcceptCharset = "utf8") {
							return tAccept
						} Else {
							// There is a non-utf8 charset specified for a supported mime type
							Set badCharset = tAcceptCharset
						}
					} Else {
						return tAccept
					}
				}
			}
		}
		If badAccept {
			// This will cause a 406 Not Acceptable to be returned in the HTTP response.
			$$$ThrowFHIR($$$HSFHIRErrInvalidAcceptSpec, tAcceptMime, $$$OutcomeInvalid(406))
		}
		if badCharset '= "" {
			// We encountered an invalid charset modifying a valid mime type in the ACCEPT header
			// This will cause a 406 Not Acceptable to be returned in the HTTP response.
			$$$ThrowFHIR($$$HSFHIRErrInvalidAcceptCharset, badCharset, $$$OutcomeInvalid(406))
		}
	}
	// If we get here, then either anything is accepted or there is no spec.
	// So we will use our default
	return $$$FHIRContentCodeJSON
}

/// Parse out the mime type and the charset value (if any, in lower case)
ClassMethod getValueAndCharset(pHeaderString As %String, Output pCharSet) As %String [ Private ]
{
	Set pCharSet = ""
	Set tAcceptMime = $ZSTRIP($PIECE(pHeaderString,";"),"<>W")
	Set tParams = $ZSTRIP($PIECE(pHeaderString,";",2,*),"*W")
	// Get the value of the charset param (if present), then if we end up using the current content type,
	// but the charset is non-null and *not* utf-8, return an error.
	Set tAcceptCharset = ""
	For tJ=1:1:$L(tParams,";") {
		Set tOneParam = $P(tParams, ";", tJ)
		Set tOneParamL = $ZCVT(tOneParam, "L")
		If ($P(tOneParamL,"=") = "charset") {
			Set pCharSet = $ZConvert($P(tOneParam, "=", 2),"L")
			Quit
		}
	}
	return tAcceptMime
}

/// Translate valid values of the _format query parameter into a "format code"
ClassMethod GetFormatForParameter(mimeType As %String)
{
	Return $Case(mimeType,
		"json": $$$FHIRContentCodeJSON,
		"application/json": $$$FHIRContentCodeJSON,
		"application/fhir+json": $$$FHIRContentCodeJSON,
		"xml": $$$FHIRContentCodeXML,
		"text/xml": $$$FHIRContentCodeXML,
		"application/xml": $$$FHIRContentCodeXML,
		"application/fhir+xml": $$$FHIRContentCodeXML,
		:"")
}

/// Translate valid values of the Content-Type header into a "format code"
ClassMethod GetFormatForContentType(mimeType As %String)
{
	Return $Case(mimeType,
		"application/x-www-form-urlencoded": $$$FHIRContentCodeForm,
		"application/xml-patch+xml": $$$FHIRContentCodeXPatch,
		"application/json-patch+json": $$$FHIRContentCodeJPatch,
		"application/json+fhir": $$$FHIRContentCodeJSON,
		"application/fhir+json": $$$FHIRContentCodeJSON,
		"application/xml+fhir": $$$FHIRContentCodeXML,
		"application/fhir+xml": $$$FHIRContentCodeXML,
		:"")
}

/// Translate valid values of the Accept header into a "format code"
ClassMethod GetFormatForAccept(mimeType As %String)
{
	return $Case(mimeType,
		"application/json+fhir":$$$FHIRContentCodeJSON,
		"application/fhir+json":$$$FHIRContentCodeJSON,
		"application/json":$$$FHIRContentCodeJSON,
		"application/xml+fhir":$$$FHIRContentCodeXML,
		"application/fhir+xml":$$$FHIRContentCodeXML,
		"application/xml":$$$FHIRContentCodeXML,
		"text/xml": $$$FHIRContentCodeXML,
		:"")
}

/// Log details of HTTP request received by CSP
ClassMethod LogCSPRequest(methodName As %String, server As %Boolean) [ Internal ]
{
	#define SysLogLevel                            $get(^%ISCLOG,1)
	#define SysLog(%level,%cat,%message,%data)     Do:$get(^%ISCLOG,1)'<%level Log^%SYS.ISCLOG($ZNAME,%level,%cat,%message,%data)
	
	Set tReadLen = $Select($system.SYS.MaxLocalLength()=3641144:3640000,1:32000)
	
	If $$$SysLogLevel<3 Quit
	
	Set data="Content-Type: "_%request.ContentType
	Set data=data_", Secure: "_%request.Secure
	Set authorization=%request.GetCgiEnv("HTTP_AUTHORIZATION")
	If authorization'="" {
		Set data=data_", Authorization: "_authorization
	}
	Set name=""
	For {
		Set name=$order(%request.Data(name))
		If name="" Quit
		Set index=""
		For {
			Set index=$order(%request.Data(name,index),1,value)
			If index="" Quit
			Set data(name,index)=value
		}
	}
	If %request.Content'="" {
		If $isobject(%request.Content) {
			Set data=data_", Content: "_%request.Content.Read(tReadLen) Do %request.Content.Rewind()
		} Else {
			Set data=data_", Content: "_%request.Content
		}
	}
	If $$$SysLogLevel>=5 {
		Set name=""
		For {
			Set name=%request.NextCookie(name)
			If name="" Quit
			Set data("Cookie",name)=%request.GetCookie(name)
		}
		Set name="HTTP_"
		For {
			Set name=$order(%request.CgiEnvs(name),1,value)
			If $extract(name,1,5)'="HTTP_" Quit
			Set data("Header",name)=value
		}
	}
	$$$SysLog(3,"HSFHIR"_$select(server:"Server",1:""),methodName_"CSP Request",.data)
}

/// Log details of HTTP response about to be returned via CSP
ClassMethod LogCSPResponse(methodName As %String, server As %Boolean) [ Internal ]
{
	#define SysLogLevel                            $get(^%ISCLOG,1)
	#define SysLog(%level,%cat,%message,%data)     Do:$get(^%ISCLOG,1)'<%level Log^%SYS.ISCLOG($ZNAME,%level,%cat,%message,%data)
	
	If $$$SysLogLevel<3 Quit
	Set data="Content-Type: "_%response.ContentType
	Set data=data_", HTTPVersion: "_%response.HTTPVersion
	Set data=data_", Status: "_%response.Status
	Set data=data_", Redirect: "_%response.Redirect
	Set data=data_", ServerSideRedirect: "_%response.ServerSideRedirect
	Set data=data_", ContentLength: "_%response.ContentLength
	If $$$SysLogLevel>=5 {
		Set name=""
		For {
			Set name=$Order(%response.Headers(name))
			If name="" Quit
			Set data("Header",name)=%response.Headers(name)
		}
		Set name=""
		For {
			Set name=$Order(%response.Cookies(name))
			If name="" Quit
			Set sub=""
			For {
				Set sub=$Order(%response.Cookies(name,sub))
				If sub="" Quit
				Set data("Cookie",name,sub)=%response.Cookies(name,sub)
			}
		}
	}
	$$$SysLog(3,"HSFHIR"_$select(server:"Server",1:""),methodName_"CSP Response",.data)
}

/// OnHandleCorsRequest overrides the same method from %CSP.REST.  FHIR CSP
/// config setting DisableCORS provides a way for an implementation to override
/// the HandleCorRequest class parameter.
ClassMethod OnHandleCorsRequest(pUrl As %String) As %Status
{
	Do ..EnsureRESTConfig()
	// This check placed here instead of in Page() or EnsureRESTConfig() because
	// Throwing from those methods causes 200 to be returned, instead of 500.
	If '$IsObject($Get(%hsrestconfig)) {
		Quit $$$ERROR($$$HSFHIRErrFHIREndpointNotDefined, %request.AppMatch)
	}
	If %hsrestconfig.DisableCORS=1 Quit $$$OK
    Quit ..HandleDefaultCorsRequest(pUrl)
}

ClassMethod EnsureRESTConfig()
{
	// Make sure we have our Configuration object.  It may be loaded already by ZAUTHENTICATE.
	if $G(%hsrestconfig)="" {
		set appKey = $$$AppKeyFromApp(%request.AppMatch)
		set %hsrestconfig = ##class(HS.Util.RESTCSPConfig).URLIndexOpen(appKey)
	}
}

}

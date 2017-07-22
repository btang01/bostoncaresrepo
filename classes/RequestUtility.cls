/*
 * Title: RequestUtility
 * Created By: Brian Tang
 * Description: Developers can use this to perform HTTP callouts
 */

 public with sharing class RequestUtility {

	public static HttpRequest Request(String url, String method, String auth, String body, String contentType) {
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod(method);
		req.setHeader('Accept', 'application/json');
		req.setHeader('Accept-Language', 'en_US');
		req.setHeader('Content-Type', contentType);
		req.setHeader('Authorization', auth);
		if(body != null){
			req.setBody(body);
		}
		req.setTimeout(120000);
		return req;
	}

	public static HttpResponse sendRequest(String url, String method, String auth, String body, String contentType){
		HttpRequest req = Request(url, method, auth, body, contentType);
		Http http = new Http();
		HttpResponse response = http.send(req);
		return response;
	}

	public static HttpResponse sendRequest(String url, String method, String auth, String body){
		return SendRequest(url, method, auth, body, 'application/json');
	}
}

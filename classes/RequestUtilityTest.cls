/*
 * Title: RequestUtility
 * Created By: Brian Tang
 * Created Date: 7/21/2017
 * Description: Covers the RequestUtility with a test callout
 */

@IsTest
public with sharing class RequestUtilityTest {
    @IsTest private static void requestTest(){
        string testUrl = 'www.google.com';
        string testMethodString = 'OPTIONS';
        string testAuth = 'some auth string';
        string testContentType = 'application/json';
        string testBody = 'this is a test';

        HttpRequest req = RequestUtility.Request(testUrl,testMethodString, testAuth, testBody, testContentType);
        System.assertEquals(req.getMethod(),testMethodString);
        System.assertEquals(req.getHeader('Content-Type'), testContentType);
        System.assertEquals(req.getHeader('Authorization'), testAuth);

    }
}

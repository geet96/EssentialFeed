//
//  RemoteLoaderTests.swift
//  EssentialFeed
//
//  Created by Geetanjali Dwiwedi on 14/08/21.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestedDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in
            
        }
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestedDataFromURLTwice() {
        let url = URL(string: "https://abc.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in }
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_deliversErrorsOnClient() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWithError: .connectivity) {
            client.complete(with: NSError(domain: "ios eeror", code: 0, userInfo: [:]))
        }
    }
    
    func test_deliversErrorOnNon200HTTPStatusCode() {
        let (sut, client) = makeSUT()
        let sampleErrorCodes = [199,201,300,400,500]
        sampleErrorCodes.enumerated().forEach { index, code in
            expect(sut, toCompleteWithError: .invalidData) {
                client.complete(with: code, at: index)
            }
        }
    }
    
    func test_deliversInvalidDataOn200HttpResponse() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWithError: .invalidData) {
            let invalidData = Data(bytes: "ascadv", count: 6)
            client.complete(with: 200, data: invalidData, at: 0)
        }
    }
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        action()
        XCTAssertEqual(capturedErrors, [error], file: file, line: line)
    }
    
    
    private class HTTPClientSpy: HTTPClient {

        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(with statusCode: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: statusCode, httpVersion: nil, headerFields: nil)
            messages[index].completion(.success(data, response!))
        }
    }
}


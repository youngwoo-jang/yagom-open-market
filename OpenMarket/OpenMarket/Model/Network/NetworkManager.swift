//
//  NetworkManager.swift
//  OpenMarket
//
//  Created by Hailey, Ryan on 2021/05/11.
//

import Foundation

struct NetworkManager: Requestable {
    
    private let session: URLSession
    
    init(_ session: URLSession) {
        self.session = session
    }
    
    enum HTTPStatusCode {
        static let success: ClosedRange<Int> = 200...299
    }
    
    func dataTask<Decoded: Decodable>(
        _ urlRequest: URLRequest,
        _ type: Decoded.Type,
        completionHandler: @escaping (Result<Decoded, APIError>) -> Void
    ) {
        session.dataTask(with: urlRequest) { data, response, error in
            guard error == nil else {
                completionHandler(.failure(.requestFailure))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completionHandler(.failure(.downcastingFailure("HTTPURLResponse")))
                return
            }
            
            guard isSuccessResponse(response) else {
                completionHandler(.failure(.networkFailure(response.statusCode)))
                return
            }
            
            guard let data = data else {
                completionHandler(.failure(.invalidData))
                return
            }
            
            guard let decodedData = try? JSONDecoder().decode(type.self, from: data) else {
                completionHandler(.failure(.decodingFailure))
                return
            }
            
            completionHandler(.success(decodedData))
        }.resume()
    }
    
    func isSuccessResponse(_ response: HTTPURLResponse) -> Bool {
        if (HTTPStatusCode.success).contains(response.statusCode) {
            return true
        } else {
            return false
        }
    }
    
    func request<Decoded: Decodable>(
        _ type: Decoded.Type,
        url: URL?,
        completionHandler: @escaping (Result<Decoded, APIError>) -> Void
    ) {
        guard let requestURL = url else { return }
        
        let request = URLRequest(url: requestURL, httpMethod: .get)
        
        dataTask(request, Decoded.self) { result in
            completionHandler(result)
        }
    }
    
    func deleteItem(
        url: URL?,
        body: ItemForDelete,
        completionHandler: @escaping (Result<ItemResponse, APIError>) -> Void
    ) {
        guard let request = makeRequest(url: url, httpMethod: .delete, body) else { return }
        
        dataTask(request, ItemResponse.self) { result in
            completionHandler(result)
        }
    }
    
    func editItem(
        url: URL?,
        body: ItemForEdit,
        completionHandler: @escaping (Result<ItemResponse, APIError>) -> Void
    ) {
        guard let request = makeRequest(url: url, httpMethod: .patch, body) else { return }
        
        dataTask(request, ItemResponse.self) { result in
            completionHandler(result)
        }
    }
    
    func registerItem(
        url: URL?,
        body: ItemForRegistration,
        completionHandler: @escaping (Result<ItemResponse, APIError>) -> Void
    ) {
        guard let request = makeRequest(url: url, httpMethod: .post, body) else { return }
        
        dataTask(request, ItemResponse.self) { result in
            completionHandler(result)
        }
    }
}

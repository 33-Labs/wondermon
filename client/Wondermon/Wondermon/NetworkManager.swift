//
//  NetworkManager.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/9.
//

import Alamofire
import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    private let endpoint = "https://wondermon-production.up.railway.app"
    
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let endpoint = "\(endpoint)/auth/login"
        let parameters = ["email": email, "password": password]
        
        AF.request(endpoint, method: .post, parameters: parameters).responseDecodable(of: UserResponse.self) { response in
            
            switch response.result {
            case .success(let userResponse):
                if userResponse.status == 0, let user = userResponse.data {
                    completion(.success(user))
                }
            case .failure(let error):
                return completion(.failure(error))
            }
        }
    }
    
    func register(username: String, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let endpoint = "\(endpoint)/auth"
        let parameters = ["name": username, "email": email, "password": password]
        
        AF.request(endpoint, method: .post, parameters: parameters).responseDecodable(of: UserResponse.self) { response in
            switch response.result {
            case .success(let userResponse):
                if userResponse.status == 0, let user = userResponse.data {
                    completion(.success(user))
                }
            case .failure(let error):
                return completion(.failure(error))
            }
        }
    }
    

    
    func chat(prompt: String, flovatarId: UInt64, messages: [String], completion: @escaping (Result<AiMessage, Error>) -> Void) {
        let endpoint = "\(endpoint)/openai/chat"
        let parameters: [String: Any] = ["prompt": prompt, "flovatarId": flovatarId]
        guard let user = UserDefaults.standard.fetchUser() else {
            completion(.failure(WMError.unauthorized))
            return
        }
        
        let headers: HTTPHeaders = [.authorization(bearerToken: user.accessToken)]
        AF.request(endpoint, method: .post, parameters: parameters, headers: headers).responseDecodable(of: AiMessageResponse.self) { response in
            debugPrint(response)
            switch response.result {
            case .success(let messageResponse):
                if messageResponse.status == 0, let message = messageResponse.data {
                    completion(.success(message))
                }
            case .failure(let error):
                return completion(.failure(error))
            }
        }
    }
}

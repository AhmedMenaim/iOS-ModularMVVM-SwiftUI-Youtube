//
//  MoviesNetworkManager.swift
//  iOS-ModularMVVM-SwiftUI-Youtube
//
//  Created by Menaim on 15/12/2025.
//

import Foundation
import Combine

//protocol NetworkManagerProtocol {
//  func perform<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, SessionDataTaskError>
//}

class NetworkManager: ObservableObject {
  func perform<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, SessionDataTaskError> {
    guard
      let url = request.url
    else {
      return Fail(error: SessionDataTaskError.notValidURL).eraseToAnyPublisher()
    }
    let request = URLRequest(url: url)
    return URLSession.shared.dataTaskPublisher(for: request)
        .tryMap { result in
          guard let httpResponse = result.response as? HTTPURLResponse else {
              throw SessionDataTaskError.requestFailed
          }
          let statusCode = httpResponse.statusCode
          switch statusCode {
          case 200..<300:
              if let url = request.url {
                  print("[\(request.httpMethod?.uppercased() ?? "")] '\(url)'")
              } else {
                  print("❌ ERROR WHILE RETRIEVING REQUEST URL ❌")
                  throw SessionDataTaskError.notValidURL
              }
              return result.data
          case 1009, 1020:
              throw SessionDataTaskError.noInternetConnection
          case 404:
              throw SessionDataTaskError.notFound
          case 400, 401:
              throw SessionDataTaskError.notAuthorized
          case 500...599:
              throw SessionDataTaskError.server
          default:
              throw SessionDataTaskError.emptyErrorWithStatusCode(httpResponse.statusCode.description)
          }
        }
        .decode(type: T.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main) // down stream
        .mapError { error -> SessionDataTaskError in
          if let error = error as? SessionDataTaskError {
            return error
          }
            return SessionDataTaskError.failWithError(error)
        }
        .eraseToAnyPublisher()

  }
}

//URL(string: "\(Constants.Network.baseURL)discover/movie?include_adult=false&sort_by=popularity.desc&page=\(currentPage)&\(Constants.Network.APIKey)")

class MoviesNetworkManager: ObservableObject {

  let manager = NetworkManager()

  func getMovies(currentPage: Int) -> AnyPublisher<MoviesNetworkResponse, SessionDataTaskError> {
    manager
      .perform(
        URLRequest(
          url: URL(
            string: "\(Constants.Network.baseURL)discover/movie?include_adult=false&sort_by=popularity.desc&page=\(currentPage)&\(Constants.Network.APIKey)"
          )!
)
)
  }
}

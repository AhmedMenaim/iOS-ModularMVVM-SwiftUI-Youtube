//
//  ContentView.swift
//  iOS-ModularMVVM-SwiftUI-Youtube
//
//  Created by Menaim on 13/10/2025.
//

import SwiftUI
import Combine

struct ContentView: View {
  @State private var cancellables: Set<AnyCancellable> = []
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
          getMovies(currentPage: 1)
            .sink { failure in
              print(failure)
            } receiveValue: { response in
              print(response.results ?? [])
            }
            .store(in: &cancellables)

        }
    }

  private func getMovies(currentPage: Int) -> AnyPublisher<MoviesNetworkResponse, SessionDataTaskError> {
    guard
      let url = URL(string: "\(Constants.Network.baseURL)discover/movie?include_adult=false&sort_by=popularity.desc&page=\(currentPage)&\(Constants.Network.APIKey)")
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
        .decode(type: MoviesNetworkResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .mapError { error -> SessionDataTaskError in
          if let error = error as? SessionDataTaskError {
            return error
          }
            return SessionDataTaskError.failWithError(error)
        }
        .eraseToAnyPublisher()

  }

}

#Preview {
    ContentView()
}

struct MoviesNetworkResponse: Decodable {
  let page: Int?
  let results: [MovieNetworkResponse]?
  let totalPages, totalResults: Int?

  enum CodingKeys: String, CodingKey {
    case page, results
    case totalPages = "total_pages"
    case totalResults = "total_results"
  }
}

// MARK: - Result
struct MovieNetworkResponse: Codable {
  let adult: Bool?
  let backdropPath: String?
  let genreIDS: [Int]?
  let id: Int?
  let originalLanguage: String?
  let originalTitle, overview: String?
  let popularity: Double?
  let posterPath, releaseDate, title: String?
  let video: Bool?
  let voteAverage: Double?
  let voteCount: Int?

  enum CodingKeys: String, CodingKey {
    case adult
    case backdropPath = "backdrop_path"
    case genreIDS = "genre_ids"
    case id
    case originalLanguage = "original_language"
    case originalTitle = "original_title"
    case overview, popularity
    case posterPath = "poster_path"
    case releaseDate = "release_date"
    case title, video
    case voteAverage = "vote_average"
    case voteCount = "vote_count"
  }
}

enum Constants {
  enum Network {
    public static let baseURL = "https://api.themoviedb.org/3/"
    public static let moviesPath = ""
    public static let genrePath = "genre/movie/list"
    public static let APIKey = ""
    public static let imageBaseURL = "https://image.tmdb.org/t/p/w500/"
  }
}

enum SessionDataTaskError: Error {
  case failWithError(Error)
  case notValidURL
  case requestFailed
  case noData
  case notFound
  case notAuthorized
  case server
  case noInternetConnection
  case emptyErrorWithStatusCode(String)
}

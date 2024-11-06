import Alamofire
import Foundation

public typealias ParameterEncoding = Alamofire.ParameterEncoding
public typealias JSONEncoding = Alamofire.JSONEncoding
public typealias URLEncoding = Alamofire.URLEncoding
public typealias Parameters = [String: Sendable]
public typealias DownloadDestination = Alamofire.DownloadRequest.Destination

public enum EndpointTask: Sendable {
    /// A request with no additional data.
    case requestPlain

    /// A requests body set with data.
    case requestData(Data)
    
    /// A requests body set with encoded parameters.
    case requestParameters(parameters: Parameters, encoding: ParameterEncoding)
    
    /// A requests body set with encoded parameters combined with url parameters.
    case requestCompositeParameters(bodyParameters: Parameters, bodyEncoding: ParameterEncoding, urlParameters: Parameters)
    
    /// A file upload task.
    case uploadFile(URL)
    
    /// A "multipart/form-data" upload task.
    case uploadMultipart([MultipartFormData])

    /// A "multipart/form-data" upload task  combined with url parameters.
    case uploadCompositeMultipart([MultipartFormData], urlParameters: Parameters)
    
    /// A file download task to a destination.
    case downloadDestination(DownloadDestination)

    /// A file download task to a destination with extra parameters using the given encoding.
    case downloadParameters(parameters: Parameters, encoding: ParameterEncoding, destination: DownloadDestination)
}

import Alamofire
import Foundation

extension AsyncNetworkProvider {
    func performRequestData(_ endpoint: Endpoint, requestToken: RequestToken?, request: URLRequest, progress: ProgressAction?) async throws(AsyncNetworkError) -> Response {
        switch endpoint.task {
        case .requestPlain, .requestData, .requestParameters, .requestCompositeParameters:
            try await sendRequest(endpoint, requestToken: requestToken, request: request, progress: progress)
        case .uploadFile(let file):
            try await sendUploadFile(endpoint, requestToken: requestToken, request: request, file: file, progress: progress)
        case .uploadMultipart(let multipartFormData):
            try await sendUploadMultipart(endpoint, requestToken: requestToken, request: request, multipartBody: multipartFormData, progress: progress)
        case let .uploadCompositeMultipart(multipartFormData, _):
            try await sendUploadMultipart(endpoint, requestToken: requestToken, request: request, multipartBody: multipartFormData, progress: progress)
        case .downloadDestination(let destination), .downloadParameters(_, _, let destination):
            try await sendDownloadRequest(endpoint, requestToken: requestToken, request: request, destination: destination, progress: progress)
        }
    }
    
    private func sendDownloadRequest(_ endpoint: Endpoint, requestToken: RequestToken?, request: URLRequest, destination: @escaping DownloadDestination, progress: ProgressAction?) async throws(AsyncNetworkError) -> Response {
        let interceptor = self.interceptor(endpoint: endpoint, configuration: RequestingConfiguration(requestToken, progress))
        let downloadRequest: DownloadRequest = session.requestQueue.sync {
            let downloadRequest = session.download(request, interceptor: interceptor, to: destination)
            setup(interceptor: interceptor, with: endpoint, and: downloadRequest, configuration: RequestingConfiguration(requestToken, progress))
            return downloadRequest
        }
        let validationCodes = endpoint.validationType.statusCodes
        let alamoRequest = validationCodes.isEmpty ? downloadRequest : downloadRequest.validate(statusCode: validationCodes)
        return try await sendAlamofireRequest(alamoRequest, endpoint: endpoint, requestToken: requestToken, progress: progress)
    }
    
    private func sendUploadMultipart(_ endpoint: Endpoint, requestToken: RequestToken?, request: URLRequest, multipartBody: [MultipartFormData], progress: ProgressAction?) async throws(AsyncNetworkError) -> Response {
        let formData = Alamofire.MultipartFormData()
        formData.applyMoyaMultipartFormData(multipartBody)
        
        let interceptor = self.interceptor(endpoint: endpoint, configuration: RequestingConfiguration(requestToken, progress))
        let uploadRequest: UploadRequest = session.requestQueue.sync {
            let uploadRequest = session.upload(multipartFormData: formData, with: request, interceptor: interceptor)
            setup(interceptor: interceptor, with: endpoint, and: uploadRequest, configuration: RequestingConfiguration(requestToken, progress))
            return uploadRequest
        }
        let validationCodes = endpoint.validationType.statusCodes
        let alamoRequest = validationCodes.isEmpty ? uploadRequest : uploadRequest.validate(statusCode: validationCodes)
        return try await sendAlamofireRequest(alamoRequest, endpoint: endpoint, requestToken: requestToken, progress: progress)
    }
    
    private func sendUploadFile(_ endpoint: Endpoint, requestToken: RequestToken?, request: URLRequest, file: URL, progress: ProgressAction?) async throws(AsyncNetworkError) -> Response {
        let interceptor = self.interceptor(endpoint: endpoint, configuration: RequestingConfiguration(requestToken, progress))
        let uploadRequest: UploadRequest = session.requestQueue.sync {
            let uploadRequest = session.upload(file, with: request, interceptor: interceptor)
            setup(interceptor: interceptor, with: endpoint, and: uploadRequest, configuration: RequestingConfiguration(requestToken, progress))
            return uploadRequest
        }
        let validationCodes = endpoint.validationType.statusCodes
        let alamoRequest = validationCodes.isEmpty ? uploadRequest : uploadRequest.validate(statusCode: validationCodes)
        return try await sendAlamofireRequest(alamoRequest, endpoint: endpoint, requestToken: requestToken, progress: progress)
    }

    private func sendRequest(_ endpoint: Endpoint, requestToken: RequestToken?, request: URLRequest, progress: ProgressAction?) async throws(AsyncNetworkError) -> Response {
        let interceptor = self.interceptor(endpoint: endpoint, configuration: RequestingConfiguration(requestToken, progress))
        let initialRequest: DataRequest = session.requestQueue.sync {
            let initialRequest = session.request(request, interceptor: interceptor)
            setup(interceptor: interceptor, with: endpoint, and: initialRequest, configuration: RequestingConfiguration(requestToken, progress))

            return initialRequest
        }
        let validationCodes = endpoint.validationType.statusCodes
        let alamoRequest = validationCodes.isEmpty ? initialRequest : initialRequest.validate(statusCode: validationCodes)
        return try await sendAlamofireRequest(alamoRequest, endpoint: endpoint, requestToken: requestToken, progress: progress)
    }

    func sendAlamofireRequest<T>(_ alamoRequest: T, endpoint: Endpoint, requestToken: RequestToken?, progress: ProgressAction?) async throws(AsyncNetworkError) -> Response where T: Requestable, T: Request {
        if let requestToken {
            await requestToken.setReqeuest(alamoRequest)
        }
        if let progress {
            switch alamoRequest {
            case let downloadRequest as DownloadRequest:
                downloadRequest.downloadProgress(queue: progress.queue, closure: progress.handler)
            case let uploadRequest as UploadRequest:
                uploadRequest.uploadProgress(queue: progress.queue, closure: progress.handler)
            case let dataRequest as DataRequest:
                dataRequest.downloadProgress(queue: progress.queue, closure: progress.handler)
            default: break
            }
        }
        let responseKind = await alamoRequest.response()
        let finalResponse: Response
        do {
            let response = try Response(responseKind)
            finalResponse = try await buildPluginsResponse(.success(response), endpoint: endpoint, configuration: RequestingConfiguration(requestToken, progress))
        } catch {
            finalResponse = try await buildPluginsResponse(.failure(error), endpoint: endpoint, configuration: RequestingConfiguration(requestToken, progress))
        }
        return finalResponse
    }

    private func setup(interceptor: AsyncRequestInterceptor, with endpoint: Endpoint, and request: Request, configuration: RequestingConfiguration) {
        Task {
            await interceptor.setWillSend { [weak request] urlRequest in
                guard let request = request else { return }
                let stubbedAlamoRequest = RequestTypeWrapper(request: request, urlRequest: urlRequest)
                plugins.forEach { $0.willSend(stubbedAlamoRequest, endpoint: endpoint, configuration: configuration) }
            }
        }
    }
    
    func buildPluginsURLRequest(_ urlRequest: URLRequest, endpoint: Endpoint, configuration: RequestingConfiguration) async throws(AsyncNetworkError) -> URLRequest {
        var result = Result<URLRequest, AsyncNetworkError>.success(urlRequest)
        for plugin in plugins {
            do {
                let value = try await plugin.prepare(urlRequest, endpoint: endpoint, configuration: configuration)
                result = .success(value)
            } catch let error as AsyncNetworkError {
                result = .failure(error)
            } catch {
                result = .failure(.underlying(error, nil))
            }
        }
        return try result.get()
    }
    
    func buildPluginsResponse(_ initResult: Result<Response, AsyncNetworkError>, endpoint: Endpoint, configuration: RequestingConfiguration) async throws(AsyncNetworkError) -> Response {
        var result = initResult
        for plugin in plugins {
            do {
                let value = try await plugin.process(result, endpoint: endpoint, configuration: configuration)
                result = .success(value)
                plugins.forEach { $0.didReceive(result, endpoint: endpoint, configuration: configuration) }
            } catch let error as AsyncNetworkError {
                result = .failure(error)
            } catch let error as AFError {
                if case .explicitlyCancelled = error {
                    result = .failure(.cancelled)
                } else {
                    result = .failure(.underlying(error, nil))
                }
            } catch {
                result = .failure(.underlying(error, nil))
            }
        }
        return try result.get()
    }
}

extension AsyncNetworkProvider {
    func interceptor(endpoint: Endpoint, configuration: RequestingConfiguration) -> AsyncRequestInterceptor {
        AsyncRequestInterceptor { urlRequest in
            try await buildPluginsURLRequest(urlRequest, endpoint: endpoint, configuration: configuration)
        }
    }
}

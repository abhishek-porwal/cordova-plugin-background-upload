
@objc(FileTransferBackground) class FileTransferBackground : CDVPlugin {
    
    
    var operationQueue: OperationQueue {
        struct Static {
            static let queue: OperationQueue = OperationQueue()
        }
        return Static.queue
    }
    
    
    @objc(startUpload:)
    func startUpload(_ command: CDVInvokedUrlCommand) {
        
        let payload = command.arguments[0] as! [String:AnyObject]
        
        operationQueue.maxConcurrentOperationCount = 1
        
        let uploadUrl  = payload["serverUrl"] as? String
        let filePath  = payload["filePath"] as? String
        let headers = payload["headers"] as? [String: String]
        var parameters = payload["parameters"] as? [String: AnyObject]
        
        if uploadUrl == nil {
            return self.returnResult(command, "invalid url", false)
        }
        
        if filePath == nil {
            return self.returnResult(command, "file path is required ", false)
        }
        
        
        if !FileManager.default.fileExists(atPath: filePath!) {
            return self.returnResult(command, "file does not exists", false)
        }
        
        if parameters == nil {
            parameters = [:]
        }
        
        
        do {
            
            parameters!["file"] = Upload(fileUrl: URL(fileURLWithPath: filePath!))
            let opt = try HTTP.POST(uploadUrl!, parameters: parameters, headers: headers)
            
            opt.onFinish = { response in
                if let err = response.error {
                    print("error: \(err.localizedDescription)")
                    
                    return self.returnResult(command, err.localizedDescription, false)
                    
                }
                //print("opt finished: \(response.description)")
                
                self.returnResult(command, response.text ?? "")
                
            }
            
            opt.progress = { progress in
                
                let pluginResult = CDVPluginResult(status:  CDVCommandStatus_OK, messageAs: ["progress" : progress*100])
                pluginResult!.keepCallback = true
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: command.callbackId
                )
                
            }
            /*
             opt.start { response in
             self.returnResult(command, response.text ?? "")
             }
             */
            
            self.operationQueue.addOperation(opt)
            
        } catch let error {
            print("got an error creating the request: \(error)")
            self.returnResult(command, "http request could not be created", false)
        }
        
        
        
    }
    
    func returnResult(_ command: CDVInvokedUrlCommand, _ msg: String, _ success:Bool = true){
        let pluginResult = CDVPluginResult(
            status: success ? CDVCommandStatus_OK : CDVCommandStatus_ERROR,
            messageAs: msg
        )
        
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
}

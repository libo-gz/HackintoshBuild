//
//  ViewControllerInfo.swift
//  HackintoshBuild
//
//  Created by wbx on 2020/2/29.
//  Copyright © 2020 wbx. All rights reserved.
//

import Cocoa

class ViewControllerInfo: NSTabViewController {
    
    @objcMembers class Info: NSObject {
        dynamic var key: String = ""
        dynamic var value: String = ""
        
        init(_ key: String, _ value: String) {
            self.key = key
            self.value = value
        }
    }

    var outputArr: [String] = []
    var output: String = ""
    @objc dynamic var info: [Info] = []
    
    @IBOutlet weak var infoTableView: NSTableView!
    
    let taskQueue = DispatchQueue.global(qos: .background)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        runBuildScripts("systeminfo")
    }
    
    func Convert(_ str: String) -> String {
        var hexStr: String = ""
        let arr = Array(str)
        for index in stride(from: arr.count-1, to: 0, by: -2) {
            hexStr.append(arr[index-1])
            hexStr.append(arr[index])
        }
        return hexStr.uppercased()
    }
    
        func runBuildScripts(_ shell: String) {
        AraHUDViewController.shared.showHUDWithTitle(title: "正在进行中")
        taskQueue.async {
            if let path = Bundle.main.path(forResource: shell, ofType:"command") {
                let task = Process()
                task.launchPath = path
                task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"]
                task.terminationHandler = { task in
                    DispatchQueue.main.async(execute: { [weak self] in
                        guard let `self` = self else { return }
                        self.outputArr = self.output.components(separatedBy: "\n")
                        MyLog(self.outputArr)
                        if self.outputArr.first!.isEmpty {
                            self.outputArr.removeFirst()
                        }
                        if self.outputArr.last!.isEmpty {
                            self.outputArr.removeLast()
                        }
                        for infoStr in self.outputArr {
                            var infoArr = infoStr.components(separatedBy: ":")
                            if infoArr[0] == "核显ig-platform-id" {
                                infoArr[1] = "0x" + self.Convert(infoArr[1])
                            }
                            self.info.append(Info(NSLocalizedString(infoArr[0], comment: ""),NSLocalizedString(infoArr[1].trimmingCharacters(in: .whitespaces), comment: "")))
                        }
                        self.infoTableView.reloadData()
                        AraHUDViewController.shared.hideHUD()
                    })
                }
                self.taskOutPut(task)
                task.launch()
                task.waitUntilExit()
            }
        }
    }
    
    func taskOutPut(_ task:Process) {
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) { notification in
            let output = outputPipe.fileHandleForReading.availableData
            if output.count > 0 {
                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.output
                    let nextOutput = previousOutput + outputString
                    self.output = nextOutput
                })
            }
        }
    }
}

extension ViewControllerInfo: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return info.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return info[row]
    }
    
}
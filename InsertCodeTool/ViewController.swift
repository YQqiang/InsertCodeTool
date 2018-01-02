//
//  ViewController.swift
//  InsertCodeTool
//
//  Created by sungrow on 2017/12/29.
//  Copyright © 2017年 sungrow. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    /// MARK - 控件属性
    
    /// 工程文件夹路径
    @IBOutlet weak var projectFileTF: NSTextField!
    
    /// 选择工程文件夹
    @IBOutlet weak var projectFileBTN: NSButton!
    
    /// 忽略的文件夹
    @IBOutlet weak var ignoreFileTF: NSTextField!
    
    /// 在头文件插入代码的文件路径
    @IBOutlet weak var insertCodeHFileTF: NSTextField!
    
    /// 选择在头文件插入代码的文件路径
    @IBOutlet weak var insertCodeHFileBTN: NSButton!
    
    /// 在实现文件插入代码的文件路径
    @IBOutlet weak var insertCodeMFileTF: NSTextField!
    
    /// 选择在实现文件插入代码的文件路径
    @IBOutlet weak var insertCodeMFileBTN: NSButton!
    
    /// 在Swift文件插入代码的文件路径
    @IBOutlet weak var insertCodeSwiftFileTF: NSTextField!
    
    /// 选择在Swift文件插入代码的文件路径
    @IBOutlet weak var insertCodeSwiftFileBTN: NSButtonCell!
    
    /// 原有函数名前缀
    @IBOutlet weak var originPrefixTF: NSTextField!
    
    /// 替换后的函数名前缀
    @IBOutlet weak var targetPrefixTF: NSTextField!
    
    /// 插入代码文件的比例
    @IBOutlet weak var insertPresentS: NSSlider!
    @IBOutlet weak var insertPresentLAB: NSTextField!
    
    /// 还原插入的代码
    @IBOutlet weak var revertCodeBTN: NSButton!
    
    /// 确定插入代码
    @IBOutlet weak var confirmInsertBTN: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    /// 信息提示
    @IBOutlet weak var messageLAB: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressIndicator.isHidden = true
    }
    
}

// MARK: - Xib控件函数
extension ViewController {
    @IBAction func projectFileBTNAction(_ sender: NSButton) {
        projectFileTF.placeholderString = openPanel(canChooseFile: false)
    }
    
    @IBAction func insertCodeHFileBTNAction(_ sender: NSButton) {
        insertCodeHFileTF.placeholderString = openPanel(canChooseFile: true)
    }
    
    @IBAction func insertCodeMFileBTNAction(_ sender: NSButton) {
        insertCodeMFileTF.placeholderString = openPanel(canChooseFile: true)
    }
    
    @IBAction func insertCodeSwiftFileBTNAction(_ sender: NSButton) {
        insertCodeSwiftFileTF.placeholderString = openPanel(canChooseFile: true)
    }
    
    @IBAction func insertPresentSAction(_ sender: NSSlider) {
        insertPresentLAB.stringValue = "\(sender.integerValue)" + "%"
    }
    
    @IBAction func revertCodeBTNAction(_ sender: NSButton) {
        confirmInsertBTN.title = sender.state == .on ? "确定删除已插入代码" : "确定插入代码"
    }
    
    @IBAction func confirmInsertBTNAction(_ sender: NSButton) {
        if projectFileTF.placeholderString == nil || projectFileTF.placeholderString?.count == 0 {
            showMessage(message: "请选择工程路径")
            return
        }
        if (insertCodeHFileTF.placeholderString == nil || insertCodeHFileTF.placeholderString?.count == 0) && (insertCodeMFileTF.placeholderString == nil || insertCodeMFileTF.placeholderString?.count == 0) && (insertCodeSwiftFileTF.placeholderString == nil || insertCodeSwiftFileTF.placeholderString?.count == 0) {
            showMessage(message: "(.h .m .swift)至少需要选择一个待插入代码文件")
            return
        }
        startExecute()
        let path = projectFileTF.placeholderString!
        DispatchQueue.global().async {
            self.readFiles(path: path)
        }
        endExecute()
    }
    
}

// MARK: - 辅助函数
extension ViewController {
    
    /// 根据路径读取文件
    ///
    /// - Parameter path: 路径
    fileprivate func readFiles(path: String) {
        let fileManager = FileManager.default
        let homePath = (path as NSString).expandingTildeInPath
        let directoryEnumerator = fileManager.enumerator(atPath: homePath)
        
        /// 统计文件个数
        var hFiles = [String]()
        var mFiles = [String]()
        var swiftFiles = [String]()
        var fileName: String? = (directoryEnumerator?.nextObject() as! String?)
//        let fileExtensions: [String] = ["h","m", "swift"]
        
        /// 不包含的文件夹
        let ignoreFileFolder = getStringValue(with: ignoreFileTF).components(separatedBy: ",")
        
        while (fileName != nil) {
            var contains = false
            for pathComp in (fileName as NSString?)?.pathComponents ?? [String]() {
                 contains = ignoreFileFolder.contains(pathComp)
                if contains {
                    break
                }
            }
            if !contains {
                if let fileExtension = (fileName as NSString?)?.pathExtension {
                    if fileExtension == "h" {
                        hFiles.append(fileName!)
                    }
                    if fileExtension == "m" {
                        mFiles.append(fileName!)
                    }
                    if fileExtension == "swift" {
                        swiftFiles.append(fileName!)
                    }
                }
            }
            fileName = (directoryEnumerator?.nextObject() as! String?)
        }
        let message = "供检索出文件:\(hFiles.count + mFiles.count + swiftFiles.count)个 \n头文件(.h):\(hFiles.count)个\n实现文件(.m):\(mFiles.count)个\nSwift文件(.swift):\(swiftFiles.count)个\n"
        showMessage(message: message)
        let insertHFileCount = insertCodeAction(insertCodeFile: insertCodeHFileTF, targetFiles: hFiles, homePath: homePath)
        let insertMFileCount = insertCodeAction(insertCodeFile: insertCodeMFileTF, targetFiles: mFiles, homePath: homePath)
        showMessage(message: message + "\n" + "头文件插入(.h): \(insertHFileCount)个" + "\n" + "实现文件(.m): \(insertMFileCount)个")
    }

    /// 插入代码实现
    ///
    /// - Parameters:
    ///   - insertCodeFile: 待插入代码的文件
    ///   - targetFiles: 目标代码文件数组
    ///   - homePath: 主目录
    /// - Returns: 已插入的文件数量
    @discardableResult
    fileprivate func insertCodeAction(insertCodeFile: NSTextField, targetFiles: [String], homePath: String) -> Int {
        var count = 0
        for (_, filePath) in targetFiles.enumerated() {
            guard canInsertCode() else {
                continue
            }
            let fileNameExten = (filePath as NSString?)?.lastPathComponent
            let fileName = (fileNameExten as NSString?)?.deletingPathExtension
            // 准备插入的代码内容
            var insertCodePath = ""
            DispatchQueue.main.sync {
                insertCodePath = insertCodeFile.placeholderString ?? ""
            }
            guard insertCodePath.count > 0 else {
                continue
            }
            guard let insertCode = insertCode(with: insertCodePath, fileName: fileName ?? "") else {
                continue
            }
            let fullPath = homePath + "/" + filePath
            let fileStr = try? String.init(contentsOfFile: fullPath, encoding: String.Encoding.utf8)
            // 文件内容
            guard var fileContent = fileStr else {
                continue
            }
            
            let suffix = "@end"
            var originCode = suffix
            var targetCode = insertCode + suffix
            if getRevertCodeStatus() {
                originCode = insertCode + suffix
                targetCode = suffix
            }
            
            let replaceRangeOption = fileContent.range(of: originCode, options: String.CompareOptions.backwards)
            guard let replaceRange = replaceRangeOption else {
                continue
            }
            fileContent.replaceSubrange(replaceRange, with: targetCode)
            try? fileContent.write(toFile: fullPath, atomically: true, encoding: String.Encoding.utf8)
            count += 1
            showMessage(message: "正在插入代码: \(fileNameExten ?? "")")
        }
        return count
    }
    
    /// 获取替换前缀后的带插入代码文件内容
    ///
    /// - Parameters:
    ///   - path: 待插入代码文件路径
    ///   - fileName: 目标插入代码的文件名称
    /// - Returns: 插入代码内容
    fileprivate func insertCode(with path: String?, fileName: String) -> String? {
        guard let p = path else {
            return nil
        }
        var content: String?
        content = try? String.init(contentsOfFile: p, encoding: String.Encoding.utf8)
        let originPrefix = getStringValue(with: originPrefixTF)
        let targetPrefix = getStringValue(with: targetPrefixTF).count > 0 ? getStringValue(with: targetPrefixTF) : fileName.filter({ (character) -> Bool in
            return "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM".contains(character)
        })
        content = content?.replacingOccurrences(of: originPrefix, with: targetPrefix)
        return content
    }
    
    /// 获取操作执行状态: 插入代码 or 删除已插入代码
    ///
    /// - Returns: 插入代码 or 删除已插入代码
    fileprivate func getRevertCodeStatus() -> Bool {
        var status = false
        DispatchQueue.main.sync {
            status = self.revertCodeBTN.state == .on
        }
        return status
    }
    
    /// 在主线程获取 `NSTextField` 的 `stringValue`
    ///
    /// - Parameter textField:
    /// - Returns:
    fileprivate func getStringValue(with textField: NSTextField) -> String {
        var stringValue = ""
        DispatchQueue.main.sync {
            stringValue = textField.stringValue
        }
        return stringValue
    }
    
    /// 根据设置的比例决定是否可以插入代码
    ///
    /// - Returns: 是否可以插入代码
    fileprivate func canInsertCode() -> Bool {
        if getRevertCodeStatus() {
            return true
        }
        var value = 0
        DispatchQueue.main.sync {
            value = insertPresentS.integerValue
        }
        return Int(arc4random() % 100) < value
    }
    
    /// 从Finder中选择文件/文件夹
    ///
    /// - Parameter canChooseFile: 是否是文件
    /// - Returns: 文件/文件夹路径
    fileprivate func openPanel(canChooseFile: Bool) -> String {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = !canChooseFile
        openPanel.canChooseFiles = canChooseFile
        if openPanel.runModal() == .OK {
            let path = openPanel.urls.first?.absoluteString.components(separatedBy: ":").last?.removingPercentEncoding as NSString?
            return path?.expandingTildeInPath ?? ""
        }
        return ""
    }
    
    /// 开始执行
    fileprivate func startExecute() {
        confirmInsertBTN.isEnabled = false
        DispatchQueue.main.async {
            self.progressIndicator.isHidden = false
            self.progressIndicator.startAnimation(nil)
        }
    }
    
    /// 结束执行
    fileprivate func endExecute() {
        confirmInsertBTN.isEnabled = true
        DispatchQueue.main.async {
            self.progressIndicator.isHidden = true
            self.progressIndicator.stopAnimation(nil)
        }
    }
    
    /// 显示提示信息
    ///
    /// - Parameter message: 提示信息
    fileprivate func showMessage(message: String) {
        DispatchQueue.main.async {
            self.messageLAB.stringValue = message
        }
    }
}


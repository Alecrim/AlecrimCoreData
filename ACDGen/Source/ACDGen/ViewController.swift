//
//  ViewController.swift
//  ACDGen
//
//  Created by Vanderlei Martinelli on 2015-02-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var chooseDataModelButton: NSButton!
    @IBOutlet weak var dataModelLabel: NSTextField!
    @IBOutlet weak var dataContextNameTextField: NSTextField!
    @IBOutlet weak var useScalarPropertiesCheckBox: NSButton!
    @IBOutlet weak var useSwiftStringCheckBox: NSButton!
    @IBOutlet weak var generateQueryAttributesCheckBox: NSButton!
    @IBOutlet weak var addPublicAccessModifierCheckBox: NSButton!
    @IBOutlet weak var gererateButton: NSButton!
    
    var dataModelFileURL: URL? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.dataModelLabel.isHidden = true
        self.dataModelLabel.stringValue = ""
        self.dataContextNameTextField.stringValue = "NSManagedObjectContext" // "DataContext"
        self.useScalarPropertiesCheckBox.state = NSOnState
        self.useSwiftStringCheckBox.state = NSOnState
        self.useSwiftStringCheckBox.isEnabled = false
        self.generateQueryAttributesCheckBox.state = NSOnState
        self.addPublicAccessModifierCheckBox.state = NSOffState
        self.gererateButton.isEnabled = false
    }
    
    @IBAction func chooseDataModelButtonPressed(_ sender: NSButton) {
        self.openExistingDocument()
    }

    @IBAction func useScalarPropertiesButtonPressed(_ sender: NSButton) {
        self.useSwiftStringCheckBox.state = NSOnState
        self.useSwiftStringCheckBox.isEnabled = self.useScalarPropertiesCheckBox.state == NSOffState
    }
    
    @IBAction func generateButtonPressed(_ sender: NSButton) {
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        
        panel.prompt = "Choose"
        panel.message = "Choose a target folder to generated code.\r\n(Existing generated files with the same name will be overwritten.)"
        
        panel.beginSheetModal(for: self.view.window!) { result in
            guard result == NSFileHandlingPanelOKButton, let url = panel.url else { return }
            
            self.enableControls(false)
            
            let alert: NSAlert
            
            do {
                let parameters = CodeGeneratorParameters(
                    dataModelFileURL: self.dataModelFileURL!,
                    targetFolderURL: url,
                    dataContextName: self.dataContextNameTextField.stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                    useScalarProperties: self.useScalarPropertiesCheckBox.state == NSOnState,
                    useSwiftString: self.useSwiftStringCheckBox.state == NSOnState,
                    generateQueryAttributes: self.generateQueryAttributesCheckBox.state == NSOnState,
                    addPublicAccessModifier: self.addPublicAccessModifierCheckBox.state == NSOnState
                )
                
                let modelCodeGenerator = ModelCodeGenerator(parameters: parameters)
                try modelCodeGenerator.generate()
                
                alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = "Success"
                alert.informativeText = "The source code files were generated successfully."
            }
            catch let error as NSError {
                alert = NSAlert(error: error)
            }
            catch {
                alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "Error"
                alert.informativeText = "An unespecified error occurred."
            }
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: { _ in
                self.enableControls(true)
            })
        }
    }
    
}

extension ViewController {
    
    func openExistingDocument() {
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false

        panel.allowedFileTypes = ["xcdatamodeld"]
        panel.allowsOtherFileTypes = false
        
        panel.prompt = "Choose"
        panel.message = "Choose a data model file."
        
        panel.beginSheetModal(for: self.view.window!) { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                if let url = panel.url {
                    self.dataModelFileURL = url
                    
                    self.chooseDataModelButton.isHidden = true
                    self.dataModelLabel.stringValue = url.lastPathComponent
                    self.dataModelLabel.isHidden = false
                    self.gererateButton.isEnabled = true
                }
            }
        }
    }
    
    func enableControls(_ enable: Bool) {
        self.chooseDataModelButton.isEnabled = enable
        self.dataModelLabel.isEnabled = enable
        self.dataContextNameTextField.isEnabled = enable
        self.useScalarPropertiesCheckBox.isEnabled = enable
        self.useSwiftStringCheckBox.isEnabled = self.useScalarPropertiesCheckBox.state == NSOffState
        self.generateQueryAttributesCheckBox.isEnabled  = enable
        self.addPublicAccessModifierCheckBox.isEnabled = enable
        self.gererateButton.isEnabled = enable
    }

}

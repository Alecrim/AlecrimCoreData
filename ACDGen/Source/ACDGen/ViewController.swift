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
    
    var dataModelFileURL: NSURL? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.dataModelLabel.hidden = true
        self.dataModelLabel.stringValue = ""
        self.dataContextNameTextField.stringValue = "DataContext"
        self.useScalarPropertiesCheckBox.state = NSOnState
        self.useSwiftStringCheckBox.state = NSOnState
        self.useSwiftStringCheckBox.enabled = false
        self.generateQueryAttributesCheckBox.state = NSOnState
        self.addPublicAccessModifierCheckBox.state = NSOffState
        self.gererateButton.enabled = false
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
        
        panel.beginSheetModalForWindow(self.view.window!) { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                if let url = panel.URL {
                    self.dataModelFileURL = url
                    
                    self.chooseDataModelButton.hidden = true
                    self.dataModelLabel.stringValue = url.lastPathComponent!
                    self.dataModelLabel.hidden = false
                    self.gererateButton.enabled = true
                }
            }
        }
    }
    
    func enableControls(enable: Bool) {
        self.chooseDataModelButton.enabled = enable
        self.dataModelLabel.enabled = enable
        self.dataContextNameTextField.enabled = enable
        self.useScalarPropertiesCheckBox.enabled = enable
        self.useSwiftStringCheckBox.enabled = self.useScalarPropertiesCheckBox.state == NSOffState
        self.generateQueryAttributesCheckBox.enabled  = enable
        self.addPublicAccessModifierCheckBox.enabled = enable
        self.gererateButton.enabled = enable
    }

}

extension ViewController {
    
    @IBAction func chooseDataModelButtonPressed(sender: NSButton) {
        self.openExistingDocument()
    }
    
    @IBAction func useScalarPropertiesButtonPressed(sender: NSButton) {
        self.useSwiftStringCheckBox.state = NSOnState
        self.useSwiftStringCheckBox.enabled = self.useScalarPropertiesCheckBox.state == NSOffState
    }

    @IBAction func generateButtonPressed(sender: NSButton) {
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        
        panel.prompt = "Choose"
        panel.message = "Choose a target folder to generated code.\r\n(Existing generated files with the same name will be overwritten.)"
        
        panel.beginSheetModalForWindow(self.view.window!) { result in
            guard result == NSFileHandlingPanelOKButton, let url = panel.URL else { return }

            self.enableControls(false)

            let alert: NSAlert
            
            do {
                let parameters = CodeGeneratorParameters(
                    dataModelFileURL: self.dataModelFileURL!,
                    targetFolderURL: url,
                    dataContextName: self.dataContextNameTextField.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()),
                    useScalarProperties: self.useScalarPropertiesCheckBox.state == NSOnState,
                    useSwiftString: self.useSwiftStringCheckBox.state == NSOnState,
                    generateQueryAttributes: self.generateQueryAttributesCheckBox.state == NSOnState,
                    addPublicAccessModifier: self.addPublicAccessModifierCheckBox.state == NSOnState
                )

                let modelCodeGenerator = ModelCodeGenerator(parameters: parameters)
                try modelCodeGenerator.generate()
                
                alert = NSAlert()
                alert.alertStyle = NSAlertStyle.InformationalAlertStyle
                alert.messageText = "Success"
                alert.informativeText = "The source code files were generated successfully."
            }
            catch let error as NSError {
                alert = NSAlert(error: error)
            }
            catch {
                alert = NSAlert()
                alert.alertStyle = NSAlertStyle.WarningAlertStyle
                alert.messageText = "Error"
                alert.informativeText = "An unespecified error occurred."
            }
            
            alert.beginSheetModalForWindow(self.view.window!, completionHandler: { _ in
                self.enableControls(true)
            })
        }
    }
    
}

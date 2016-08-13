//
//  main.swift
//  acdgenp
//
//  Created by Vanderlei Martinelli on 2016-03-25.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

func printHeader() {
    print("")
    print("acdgenp -- AlecrimCoreData Code Generator command line tool")
    print("Copyright (c) 2015, 2016 Alecrim. All rights reserved.")
    print("-----------------------------------------------------------")
    print("")
}

func printFooter() {
    print("")
}


// MARK: - cli

let cli = CommandLine()

let dataModelFileURLOption = StringOption(shortFlag: "i", required: true, helpMessage: "Core Data model file.")
let targetFolderURLOption = StringOption(shortFlag: "o", required: true, helpMessage: "Generated files target folder.")
let dataContextNameOption = StringOption(shortFlag: "n", required: false, helpMessage: "Data context class name.")
let useScalarPropertiesOption = BoolOption(shortFlag: "s", required: false, helpMessage: "Use scalar properties for primitive data types.")
let useSwiftStringOption = BoolOption(shortFlag: "w", required: false, helpMessage: "Use Swift String for string types.")
let generateQueryAttributesOption = BoolOption(shortFlag: "a", required: false, helpMessage: "Generate AlecrimCoreData query attributes.")
let addPublicAccessModifierOption = BoolOption(shortFlag: "p", required: false, helpMessage: "Add \"public\" access modifier.")

cli.addOptions([
    dataModelFileURLOption,
    targetFolderURLOption,
    dataContextNameOption,
    useScalarPropertiesOption,
    useSwiftStringOption,
    generateQueryAttributesOption,
    addPublicAccessModifierOption
    ])

do {
    try cli.parse()
}
catch {
    printHeader()
    cli.printUsage()
    printFooter()
    
    exit(EX_USAGE)
}

// MARK: - URL options

let fm = NSFileManager.defaultManager()

//

let dataModelFileURL = NSURL(fileURLWithPath: dataModelFileURLOption.value!)

var isDataModelFileURLDirectory: ObjCBool = false
if !fm.fileExistsAtPath(dataModelFileURL.path!, isDirectory: &isDataModelFileURLDirectory) {
    printHeader()
    print("Core data model file not found.")
    printFooter()

    exit(EX_USAGE)
}

//
let targetFolderURL = NSURL(fileURLWithPath: targetFolderURLOption.value!)

var isTargetFolderURLDirectory: ObjCBool = true
if !fm.fileExistsAtPath(targetFolderURL.path!, isDirectory: &isTargetFolderURLDirectory) {
    printHeader()
    print("Target folder not found.")
    printFooter()

    exit(EX_USAGE)
}

if !isTargetFolderURLDirectory {
    printHeader()
    print("Target must be a directory.")
    printFooter()

    exit(EX_USAGE)
}

//
let dataContextName = dataContextNameOption.value ?? ""

if dataContextName.containsString(" ") {
    printHeader()
    print("Data context class name cannot contain spaces.")
    printFooter()

    exit(EX_USAGE)
}

// MARK: - other options

let useScalarProperties = useScalarPropertiesOption.value
let useSwiftString = useSwiftStringOption.value
let generateQueryAttributes = generateQueryAttributesOption.value
let addPublicAccessModifier = addPublicAccessModifierOption.value

// MARK: - generate

do {
    let parameters = CodeGeneratorParameters(
        dataModelFileURL: dataModelFileURL,
        targetFolderURL: targetFolderURL,
        dataContextName: dataContextName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()),
        useScalarProperties: useScalarProperties,
        useSwiftString: useSwiftString,
        generateQueryAttributes: generateQueryAttributes,
        addPublicAccessModifier: addPublicAccessModifier
    )
    
    let modelCodeGenerator = ModelCodeGenerator(parameters: parameters)
    try modelCodeGenerator.generate()
    
    printHeader()
    print("The source code files were generated successfully.")
    printFooter()

    exit(EX_OK)
}
catch let error as NSError {
    printHeader()
    print("Error: \(error.description)")
    printFooter()

    exit(EX_CANTCREAT)
}


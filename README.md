![AlecrimCoreData](https://raw.githubusercontent.com/Alecrim/AlecrimCoreData/master/AlecrimCoreData.png)

[![Language: Swift](https://img.shields.io/badge/lang-Swift-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://raw.githubusercontent.com/Alecrim/AlecrimCoreData/develop/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/v/AlecrimCoreData.svg?style=flat)](http://cocoapods.org)
[![Forks](https://img.shields.io/github/forks/Alecrim/AlecrimCoreData.svg?style=flat)](https://github.com/Alecrim/AlecrimCoreData/network)
[![Stars](https://img.shields.io/github/stars/Alecrim/AlecrimCoreData.svg?style=flat)](https://github.com/Alecrim/AlecrimCoreData/stargazers)

AlecrimCoreData is a framework to easily access Core Data objects in Swift.

## Getting Started

### Data Context

To use AlecrimCoreData you will need to create a inherited class from `AlecrimCoreData.Context` and declare a property or method for each entity in your data context like the example below:

```swift
import AlecrimCoreData

let dataContext = DataContext()!

class DataContext: Context {
	var people:      Table<Person>     { return Table<Person>(context: self) }
	var departments: Table<Department> { return Table<Department>(context: self) }
}
```

It's important that properties (or methods) always return a _new_ instance of a `AlecrimCoreData.Table` class.

### Entities

It's assumed that all entity classes was already created and added to the project. In the above section example there are two entities: `Person` and `Department`.

### ACDGen

You can write managed object classes by hand or generate them using Xcode. Now you can also use ACDGen. ;-)

ACDGen app is a Core Data entity class generator made with AlecrimCoreData in mind. It is completely optional, but since it can also generate attribute class members for use in closure parameters, the experience using AlecrimCoreData is greatly improved.

You can open it from the `Bin` folder.

## Usage

### Fetching

#### Basic Fetching

Say you have an Entity called Person, related to a Department (as seen in various Apple Core Data documentation). To get all of the Person entities as an array, use the following methods:

```swift
for person in dataContext.people {
	println(person.firstName)
}
```

You can also skip some results:

```swift
let people = dataContext.people.skip(3)
```

Or take only some results:

```swift
let people = dataContext.people.skip(3).take(7)
```

Or, to return the results sorted by a property:

```swift
let peopleSorted = dataContext.people.orderBy({ $0.lastName })
```

Or, to return the results sorted by multiple properties:

```swift
let peopleSorted = dataContext.people
	.orderBy { $0.lastName }
    .thenBy { $0.firstName }

// OR

let peopleSorted = dataContext.people.sortBy("lastName,firstName")
```

Or, to return the results sorted by multiple properties with different attributes:

```swift
let peopleSorted = dataContext.people
	.orderByDescending { $0.lastName }
    .thenByAscending { $0.firstName }

// OR

let peopleSorted = dataContext.people.sortBy("lastName:0,firstName:1")

// OR

let peopleSorted = dataContext.people.sortBy("lastName:0:[cd],firstName:1:[cd]")
```

If you have a unique way of retrieving a single object from your data store (such as via an identifier), you can use the following code:

```swift
if let person = dataContext.people.first({ $0.identifier == 123 }) {
	println(person.name)
}
```

#### Count Entities

You can perform a count of the entities in your Persistent Store:

```swift
let count = dataContext.people.filter({ $0.lastName == "Smith" }).count()
```

Or:

```swift
let count = dataContext.people.count({ $0.lastName == "Smith" })
```

#### Aggregate Functions

You can use aggregate functions on a single attribute:

```swift
let total = dataContext.entities.sum({ $0.value })
```

The `sum`, `min`, `max` and `average` functions are supported. If the original property is an `Optional` the result will be an `Optional` too.

#### Selecting Only Some Attributes

You can specify an attribute to select:

```swift
let lastNames = dataContext.people.select({ $0.lastName }).distinct()
```

Or multiple properties to select:

```swift
let firstAndLastNames = dataContext.people.select(["firstName", "lastName"])
```

In both cases the result is an array of `NSDictionary`.

#### Advanced Fetching

If you want to be more specific with your search, you can use filter predicates:

```swift
let itemsPerPage = 10  

for pageNumber in 0..<5 {
	println("Page: \(pageNumber)")
	
	let peopleInCurrentPage = dataContext.people
	    .filter { $0.department << [dept1, dept2] }
	    .orderBy { $0.firstName }
	    .thenBy { $0.lastName }
	    .skip(pageNumber * itemsPerPage)
	    .take(itemsPerPage)
	
	for person in peopleInCurrentPage {
	    println("\(person.firstName) \(person.lastName) - \(person.department.name)")
	}
}
```

#### Collection Operators

You can use collection operators for "to many" relationships:

```swift
let crowdedDepartments = dataContext.departments.filter { $0.people.count > 100 }
```

Only the `count` operator is supported in this version.

#### Asynchronous Fetching

You can also fetch entities asynchronously and get the results later on main thread:

```swift
let progress = dataContext.people.fetchAsync { fetchedEntities, error in
    if error != nil {
        // Do a nice error handling here
    }
}
```

#### Returning an Array

The data is actually fetched from Persistent Store only when `toArray()` is explicitly or implicitly called. So you can combine and chain other methods before this.

```swift
let peopleArray = dataContext.people.toArray()

// OR

let peopleArray = dataContext.people.sortBy("firstName,lastName").toArray()

// OR

let theSmiths = dataContext.people
	.filter { $0.lastName == "Smith" }
    .orderBy { $0.firstName }
    
let count = theSmiths.count()
let array = theSmiths.toArray()

// OR

for person in dataContext.people.sortBy("firstName,lastName") {
	// .toArray() is called implicitly when enumerating
}
```

#### Converting to other class types

Call the `to...` method in the end of chain.

```swift
let fetchRequest = dataContext.people.toFetchRequest()

// OS X only
let arrayController = dataContext.people.toArrayController()

// iOS only (returns an AlecrimCoreData FecthedResultsController strong typed instance)
let fetchedResultsController = dataContext.people.toFetchedResultsController() 

// iOS only (returns a native NSFetchedResultsController instance)
let fetchedResultsController = dataContext.people.toNativeFetchedResultsController()

```

### Creating new Entities

When you need to create a new instance of an Entity, use:

```swift
let person = dataContext.people.createEntity()
```

You can also create or get first existing entity matching the criteria. If the entity does not exist, a new one is created and the specified attribute is assigned from the searched value automatically.

```swift
let person = dataContext.people.firstOrCreated({ $ 0.identifier == 123 })
```

### Deleting Entities

To delete a single entity:

```swift
if let person = dataContext.people.first({ $0.identifier == 123 }) {
	dataContext.people.deleteEntity(person)
}
```

To delete many entities:

```swift
dataContext.departments.filter({ $0.people.count == 0 }).delete()
```


### Saving

You can save the data context in the end, after all changes were made.

```swift
let person = dataContext.people.firstOrCreated({ $0.identifier == 9 })
person.firstName = "Christopher"
person.lastName = "Eccleston"
person.additionalInfo = "The best Doctor ever!"

// get success and error
let (success, error) = dataContext.save()
if success {
	// ...
}
else {
	println(error)
}
```

#### Threading

You can fetch and save entities in background calling a global function that creates a new data context instance for this:

```swift
// assuming that this department is saved and exists...
let department = dataContext.departments.first({ $0.identifier == 100 })!

// the closure below will run in a background context queue
performInBackground(dataContext) { bgc in
	if let person = bgc.people.first({ $0.identifier == 321 }) {
	    // we must bring department to our background context
	    person.department = department.inContext(bgc)! 
	    person.otherData = "Other Data"
	}
	
	if bgc.save().0 {
		// ...
	}
}
```

### Batch Updates

You can do batch updates on a single attribute using:

```swift
dataContext.entities.batchUpdate({ ($0.modified, true) }) { countOfUpdatedEntities, error in
    if error == nil {
		// ...
	}
}
```

Or you can specify multiples properties to update:

```swift
dataContext.entities.batchUpdate(["modified" : true, "dateModified" : NSDate()]) { countOfUpdatedEntities, error in
	if error == nil {
		// ...
	}
}
```

### Advanced Configuration

You can use `ContextOptions` class for a custom configuration.

#### App Extensions

See `Samples` folder for a configuration example for use in the main app and its extensions.


#### iCloud Core Data sync

See `Samples` folder for a configuration example for iCloud Core Data sync.


#### Ensembles

See `Samples` folder for a configuration example for [Ensembles](http://www.ensembles.io).

## Using

### Minimum Requirements

- Xcode 6.3
- iOS 8.0 / OS X 10.10

### Installation

#### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

CocoaPods 0.36 adds supports for Swift and embedded frameworks. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate AlecrimCoreData into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'AlecrimCoreData', '~> 3.0'
```

Then, run the following command:

```bash
$ pod install
```

#### Manually

You can add AlecrimCoreData as a git submodule, drag the `AlecrimCoreData.xcodeproj` file into your Xcode project and add the framework product as an embedded binary in your application target.

### Branches and Contribution

- master - The production branch. Clone or fork this repository for the latest copy.
- develop - The active development branch. [Pull requests](https://help.github.com/articles/creating-a-pull-request) should be directed to this branch.

If you want to contribute, please feel free to fork the repository and send pull requests with your fixes, suggestions and additions. :-)

### Inspired By

- [MagicalRecord](https://github.com/magicalpanda/MagicalRecord)
- [QueryKit](https://github.com/QueryKit/QueryKit)


### Version History

- 3.x - Swift framework: added attributes support and many other improvements
- 2.x - Swift framework: public open source release
- 1.x - Objective-C framework: private Alecrim team use

---

## Contact

- [Vanderlei Martinelli](https://github.com/vmartinelli)

## License

AlecrimCoreData is released under an MIT license. See LICENSE for more information.

![AlecrimCoreData](images/AlecrimCoreData.png?raw=true)

AlecrimCoreData is a framework to access Core Data objects more easily in Swift.

## Features

- Simpler classes and methods to access and save Core Data managed objects
- Main and background contexts support
- Core Data SQLite store type support with automatic creation of store file
- In memory store type support

### TODO:

- Add iCloud support to SQLite store type
- Add migration methods
- Create example projects

## Minimum Requirements

- Xcode 6.1
- iOS 7 / OS X 10.10

## Installation

You can add AlecrimCoreData as a git submodule, drag the `AlecrimCoreData.xcodeproj` file into your Xcode project and add the framework product as a dependency for your application target.

## Getting Started

### Data Model

You can create a inherited class from `CoreDataModel` and declare a property or method for each entity in your data model like the example below:

```swift
import AlecrimCoreData

public let db = DataModel()

public class DataModel: CoreDataModel {
	
	public var people:      CoreDataTable<PersonEntity>     { return CoreDataTable<PersonEntity>(dataModel: self) }
	public var departments: CoreDataTable<DepartmentEntity> { return CoreDataTable<DepartmentEntity>(dataModel: self) }

	private convenience init() {
		self.init(modelName: nil)
	}
	
}
```

It's important that properties (or methods) always return a _new_ instance of a `CoreDataTable` class.

### Entities

It's assumed that all entity classes was already created and added to the project.

In the above section example, there are two entities: `Person` and `Department` (with `Entity` suffix added to their class names). You can name the entity classes as you like, of course.

## Usage

### Fetching

#### Basic Fetching

Say you have an Entity called Person, related to a Department (as seen in various Apple Core Data documentation [and MagicalRecord documentation too]). To get all of the Person entities as an array, use the following methods:

```swift
for person in db.people {
	println(person.firstName)
}
```

You can also skip some results:

```swift
let people = db.people.skip(3)
```

Or take only some results:

```swift
let people = db.people.skip(3).take(7)
```

Or, to return the results sorted by a property:

```swift
let peopleSorted = db.people.orderBy("lastName")
```

Or, to return the results sorted by multiple properties:

```swift
let peopleSorted = db.people.orderBy("lastName").orderBy("firstName")

// OR

let peopleSorted = db.people.sortBy("lastName,firstName")
```

Or, to return the results sorted by multiple properties with different attributes:

```swift
let peopleSorted = db.people.orderByDescending("lastName").orderBy("firstName")

// OR

let peopleSorted = db.people.sortBy("lastName:0,firstName:1")

// OR

let peopleSorted = db.people.sortBy("lastName:0:[cd],firstName:1:[cd]")
```

If you have a unique way of retrieving a single object from your data store (such as via an identifier), you can use the following code:

```swift
if let person = db.people.filterBy(attribute: "identifier", value: "123").first() {
	println(person.name)
}
```

#### Advanced Fetching

If you want to be more specific with your search, you can use predicates:

```swift
let itemsPerPage = 10   

for pageNumber in 0..<5 {
	println("Page: \(pageNumber)")

	let peopleInCurrentPage = db.people
		.filterBy(predicateFormat: "department IN %@", argumentArray: [[dept1, dept2]])
		.skip(pageNumber * itemsPerPage)
		.take(itemsPerPage)
		.sortBy("firstName,lastName")

	for person in peopleInCurrentPage {
		println("\(person.firstName) \(person.lastName) - \(person.department.name)")
	}
}

// OR

let itemsPerPage = 10   
let predicate = NSPredicate(format: "department IN %@", argumentArray: [[dept1, dept2]])

for pageNumber in 0..<5 {
	println("Page: \(pageNumber)")

	let peopleInCurrentPage = db.people
		.filterBy(predicate: predicate)
		.skip(pageNumber * itemsPerPage)
		.take(itemsPerPage)
		.sortBy("firstName,lastName")

	for person in peopleInCurrentPage {
		println("\(person.firstName) \(person.lastName) - \(person.department.name)")
	}
}
```

#### Returning an Array

The data is actually fetched from Persistent Store only when `toArray()` is explicitly or implicitly called. So you can combine and chain other methods before this.

```swift
let peopleArray = db.people.toArray()

// OR

let peopleArray = db.people.sortBy("firstName,lastName").toArray()

// OR

let theSmiths = db.people.filterBy(attribute: "lastName", value: "Smith").orderBy("firstName")
let count = theSmiths.count()
let array = theSmiths.toArray()

// OR

for person in db.people.sortBy("firstName,lastName") {
    // .toArray() is called implicitly when enumerating
}
```

#### Converting to other class types

Call the `to...` method in the end of chain.

```swift
let peopleFetchRequest = db.people.toFetchRequest()
let peopleArrayController = db.people.toArrayController() // OS X only
let peopleFetchedResultsController = db.people.toFetchedResultsController() // iOS only
```

#### Find the number of entities

You can also perform a count of the entities in your Persistent Store:

```swift
let count = db.people.filterBy(attribute: "lastName", value: "Smith").count()
```

### Creating new Entities

When you need to create a new instance of an Entity, use:

```swift
let person = db.people.createEntity()
```

You can also create or get first existing entity matching the criteria. If the entity does not exist, a new one is created and the specified attribute is assigned from the searched value automatically.

```swift
let person = db.people.createOrGetFirstEntity(whereAttribute: "identifier", isEqualTo: "123")
```

### Deleting Entities

To delete a single entity:

```swift
if let person = db.people.filterBy(attribute: "identifier", value: "123").first() {
    db.people.deleteEntity(person)
}
```

## Saving

You can save the data model context in the end, after all changes were made.

```swift
let person = db.people.createOrGetFirstEntity(whereAttribute: "identifier", isEqualTo: "9")
person.firstName = "Christopher"
person.lastName = "Eccleston"
person.additionalInfo = "The best Doctor ever!"

// synchronous
let (success, error) = db.save()

// OR

// asynchronous
db.save { success, error in
    //
}
```

#### Rolling back

To rollback the data model context:

```swift
db.rollback()
```

This only works if the data model context was not saved yet.

### Threading

You can fetch and save entities in background calling a global function that creates a new data model instance for this:

```swift
// assuming that this department is saved and exists...
let department = db.departments.filterBy(attribute: "identifier", value: "100").first()!

// the closure below will run in a background context queue
performInBackground(db) { backgroundDB in
    if let person = backgroundDB.people.filterBy(attribute: "identifier", value: "321").first() {
        // bringing the department entity to the background data model context before the assignment...
        person.department = department.inDataModel(backgroundDB)!
        person.otherData = "Other Data"
    }
    
    // we are already in background here, so we can call save directly    
    let (success, error) = backgroundDB.save()
    if success {
        // ...
    }
}
```

## Contribute

If you want to contribute, please feel free to fork the repository and send pull requests with your suggestions and additions. :-)

---

## Contact

- [Vanderlei Martinelli](http://github.com/vmartinelli)

## License

AlecrimCoreData is released under an MIT license. See LICENSE for more information.

![AlecrimCoreData](https://raw.githubusercontent.com/Alecrim/AlecrimCoreData/master/AlecrimCoreData.png)

[![Language: Swift](https://img.shields.io/badge/lang-Swift-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://raw.githubusercontent.com/Alecrim/AlecrimCoreData/develop/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/v/AlecrimCoreData.svg?style=flat)](http://cocoapods.org)
[![Forks](https://img.shields.io/github/forks/Alecrim/AlecrimCoreData.svg?style=flat)](https://github.com/Alecrim/AlecrimCoreData/network)
[![Stars](https://img.shields.io/github/stars/Alecrim/AlecrimCoreData.svg?style=flat)](https://github.com/Alecrim/AlecrimCoreData/stargazers)

A powerful and simple Core Data wrapper framework written in Swift.

## Using the framework

### The basics

#### Data context

**AlecrimCoreData** provides a default `NSManagedObjectContext` subclass that can be used as is, extended, or not used at all. If used it will help you with several Core Data related tasks.

It is possible to use the framework with a "vanilla" `NSManagedObjectContext` too. In this case you will have the liberty to configure the Core Data stack as you want.

Mixing `DataContext` and "vanilla" `NSManagedObjextContext` instances is possible but is strongly discouraged.

```swift
// Initializes a `DataContext` instance with default options.
let dataContext = DataContext()
```
**Note:** The `DataContext()` function provides a *unique* instance of a *dataContext* object on the main thread, so make sure to avoid core data concurrency violations.  


#### Table

The generic `Table<T>` struct is the base for **AlecrimCoreData** functionality and is where the fun begins. `T`, in this case, is a `NSManagedObject` subclass type.

```swift
// Extends the `DataContext` class to include entity table properties.
// (It would be the `NSManagedObjectContext` class too.)
extension DataContext {
    var people:      Table<Person>     { return Table<Person>(dataContext: self) }
    var departments: Table<Department> { return Table<Department>(dataContext: self) }
}
```
##### Fetching

Say you have an `NSManagedObject` subclass type called `Person`, related to a `Department`. To get all of the `Person` entities as an array, use the following methods:

```swift
for person in dataContext.people {
    println(person.firstName)
}
```

You can also skip some results:

```swift
let people = dataContext.people.skip(3)
```

Or take some results only:

```swift
let people = dataContext.people.skip(3).take(7)
```

Or, to return the results sorted by a property:

```swift
let sortedPeople = dataContext.people.orderBy { $0.lastName }
```
Or, to return the results sorted by multiple properties:

```swift
let sortedPeople = dataContext.people
    .orderBy { $0.lastName }
    .thenBy { $0.firstName }
```

Or, to return the results sorted by multiple properties, ascending or descending:

```swift
let sortedPeople = dataContext.people
    .orderByDescending { $0.lastName }
    .thenByAscending { $0.firstName }
```

If you have a unique way of retrieving a single entity from your data store (such as via an identifier), you can use the `first` method:

```swift
if let person = dataContext.people.first({ $0.identifier == 123 }) {
    println(person.name)
}
```

##### Filtering

You can filter the results using the `filter` method:

```swift
let filteredPeople = dataContext.people.filter { $0.lastName == "Smith" }
```

You can combine multiple filters and other methods as well:

```swift
let filteredPeople = dataContext.people
    .filter { $0.lastName == "Smith" }
    .filter { $0.firstName.beginsWith("J") }
    .orderBy { $0.lastName }
    .thenBy { $0.firstName }
```

Or:

```swift
let filteredPeople = dataContext.people
    .filter { $0.lastName == "Smith" && $0.firstName.beginsWith("J") }
    .orderBy { $0.lastName }
    .thenBy { $0.firstName }
```

##### Counting

You can count entities in your persistent store using the `count` method.

```swift
let peopleCount = dataContext.people.count()
```

Or:

```swift
let filteredPeopleCount = dataContext.people.count { $0.lastName == "Smith" }
```

Or:

```swift
let filteredPeopleCount = dataContext.people
    .filter { $0.lastName == "Smith" }
    .count()
```

#### Create, update, delete and save

##### Creating and updating entities

When you need to create a new instance of an Entity, use:

```swift
let person = dataContext.people.createEntity()
```

You can also create or get the first existing entity matching the criteria. If the entity does not exist, a new one is created and the specified attribute is assigned from the searched value automatically.

```swift
let person = dataContext.people.firstOrCreated { $ 0.identifier == 123 }
```

##### Deleting entities

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

##### Saving

You can save the data context in the end, after all changes were made.

```swift
let person = dataContext.people.firstOrCreated { $0.identifier == 9 }
person.firstName = "Christopher"
person.lastName = "Eccleston"
person.additionalInfo = "The best Doctor ever!"

do {
    dataContext.save()
}
catch let error {
    // do a nice error handling here
}
```

#### Strongly-typed query attributes and ACDGen

Another important part of **AlecrimCoreData** is the use of strongly-typed query attributes.  A lot of boilerplate code is required to support strongly typed queries. With this in mind, the **ACDGen** tool was created. All you have to do is point `ACDGen` to your managed object model and the source code for the entities is automatically generated, including the **AlecrimCoreData** query attributes if you want.

Using the generated strongly-typed query attributes is completely optional, but with them the experience with **AlecrimCoreData** is greatly improved. *The use of strongly-typed query attributes requires a project that has generated extensions of it's model classes using `ACDGen`.* 

**ACDGen** binary and source code are avaible on "ACDGen/Bin" and "ACDGen/Source" folders respectively.

### Advanced use

OK. You can write code like this:

```swift
// No data access is made here.
let peopleInDepartments = dataContext.people
    .filter { $0.department << [dept1, dept2] }
    .orderBy { $0.firstName }
    .thenBy { $0.lastName }
        
let itemsPerPage = 10  

for pageNumber in 0..<5 {
    println("Page: \(pageNumber)")

    // No data access is made here either.
    let peopleInCurrentPage = peopleInDepartments
        .skip(pageNumber * itemsPerPage)
        .take(itemsPerPage)

    // Now is when the data is read from persistent store.
    for person in peopleInCurrentPage {
        println("\(person.firstName) \(person.lastName) - \(person.department.name)")
    }
}
```

But you can do even more with **AlecrimCoreData**.

There is a implementation of `NSFetchedResultsController` (for OS X) and `FetchRequestController` that is a strongly-typed wrapper for `NSFetchedResultsController`.

You are invited to read the code and discover more possibilities (and to help us to improve them and create new ones).


#### Advanced methods

There are methods for aggregating, asynchronous fetching in background and many others. You can read the **AlecrimCoreData** documentation at http://cocoadocs.org/docsets/AlecrimCoreData for more information.

#### Ordering and filtering

You can order and filter entities not using the **AlecrimCoreData** query attributes at all. In this case you lose the strongly-typed attributes, but gain in flexibility. You can even mix the two approaches without any problem.

##### Ordering

You can order the entities using `NSSortDescriptor` instances:

```swift
let sortDescriptor: NSSortDescriptor = ...
let orderedPeople = dataContext.sortUsingSortDescriptor(sortDescriptor)
```

Or:

```swift
let sd1: NSSortDescriptor = ...
let sd2: NSSortDescriptor = ...

let orderedPeople = dataContext.sortUsingSortDescriptors([sd1, sd2])
```

You can also use the `sortByAttributeName:::` method:

```swift
let orderedPeople = dataContext.sortByAttributeName("lastName", ascending: true)
```

##### Filtering

You can filter entities using `NSPredicate` instances:

```swift
let predicate: NSPredicate = ...
let filteredPeople = dataContext.people.filterUsingPredicate(predicate)
```

#### Data context options

If you want to use the `DataContext` class and initialize it's instance without parameters **AlecrimCoreData** will try to infer the managed object model and the persistent store locations, based on most common cases.

You can however create and configure a `DataContextOptions` struct and pass it as parameter to `DataContext` initializer.

There are helper initializers on `DataContextOptions`, but if you know the URLs or know how to construct them it may be better to pass these locations yourself to the `DataContextOptions` initializer directly.

Other options can be configured using `DataContextOptions` (the `defaultBatchSize` and `defaultComparisonPredicateOptions` properties). Unlike the managed object model and persistent store locations, these options are global and static for the entire framework (and your project).

#### iCloud Core Data Sync

Since **AlecrimCoreData** version 4 the configuration of your Core Data managed object contexts to include iCloud integration are not made by the framework anymore. This type of integration is very trick and we think it is better a manually approach, case by case, including your own observers and handlers. You can, however, use the `configureUbiquityWithContainerIdentifier:::` method and the  `ubiquityEnabled` property from the `DataContextOptions` struct to help you to configure iCloud integration if you want.

#### Ensembles and other third-party frameworks

Since **AlecrimCoreData** version 4 the `DataContext` is an `NSManagedObjectContext` subclass and the framework can work with "vanilla" `NSManagedObjectContext` instances as well. So you can integrate and use other frameworks as you are using only `NSManagedObjectContext` instances and there should be no side effects.

## Using

### Minimum Requirements

- Swift 2
- Xcode 7.0
- OS X 10.9 / iOS 8.0 / watchOS 2.0

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

pod 'AlecrimCoreData', '~> 4.0'
```

Then, run the following command:

```bash
$ pod install
```

#### Manually

You can add AlecrimCoreData as a git submodule, drag the `AlecrimCoreData.xcodeproj` file into your Xcode project and add the framework product as an embedded binary in your application target.

## Inspiration
- [MagicalRecord](https://github.com/magicalpanda/MagicalRecord)
- [LINQ (Language-Integrated Query)](https://msdn.microsoft.com/en-us/library/bb397926.aspx)
- [QueryKit](https://github.com/QueryKit/QueryKit)

## Branches and contribution

- master - The production branch. Clone or fork this repository for the latest copy.
- develop - The active development branch. [Pull requests](https://help.github.com/articles/creating-a-pull-request) should be directed to this branch.

If you want to contribute, please feel free to fork the repository and send pull requests with your fixes, suggestions and additions. :-)

The main areas the framework needs improvement:

- Correct the README, code and examples for English mistakes;
- Write more and better code documentation;
- Write unit tests;
- Replace some pieces of code with more "elegant" ones.

---

## Contact
- [Vanderlei Martinelli](https://github.com/vmartinelli)

## License
**AlecrimCoreData** is released under an MIT license. See LICENSE for more information.

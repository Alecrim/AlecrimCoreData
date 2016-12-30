![AlecrimCoreData](https://raw.githubusercontent.com/Alecrim/AlecrimCoreData/master/AlecrimCoreData.png)

[![Language: Swift](https://img.shields.io/badge/lang-Swift 3-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platform](https://img.shields.io/cocoapods/p/AlecrimCoreData.svg?style=flat)](http://cocoadocs.org/docsets/AlecrimCoreData)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://raw.githubusercontent.com/Alecrim/AlecrimCoreData/develop/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/v/AlecrimCoreData.svg?style=flat)](http://cocoapods.org)
[![Apps](https://img.shields.io/cocoapods/at/AlecrimCoreData.svg?style=flat)](http://cocoadocs.org/docsets/AlecrimCoreData)
[![Twitter](https://img.shields.io/badge/twitter-@vmartinelli-blue.svg?style=flat)](https://twitter.com/vmartinelli)

A powerful and simple Core Data wrapper framework written in Swift.

## Using the framework

### The basics

#### Persistent container

**AlecrimCoreData** provides a default `PersistentContainer` class that can be used as is, extended, or not used at all. If used, it will help you with several Core Data related tasks.

(The provided `PersistentContainer` class can be used with previous versions of Apple operating systems too [iOS 9, for example].)

It is possible to use the framework with a "vanilla" `NSPersistentContainer` if you prefer. In this case you will have the liberty to configure the Core Data stack as you want, but only for newer Apple operating systems (iOS 10, for example).

```swift
// Initializes a `PersistentContainer` instance with default options.
let container = PersistentContainer(name: "ModelName")
```

#### Generic persistent container

If you have subclassed the default manage object context class or want to change some of the persistent container behaviors you can use the `GenericPersistentContainer` class for this:

```swift
class MyContext: NSManagedObjectContext {
    // ...
}

class MyPersistentContainer: GenericPersistentContainer<MyContext> {
    // ...
}
```

(The `PersistentContainer` class is a `GenericPersistentContainer<NSManagedObjectContext>` subclass actually.)

#### Table

The generic `Table<T>` struct is the base for **AlecrimCoreData** functionality and is where the fun begins. `T`, in this case, is a `NSManagedObject` subclass type.

```swift
// Extends the `NSManagedObjectContext ` class to include entity table properties.
extension NSManagedObjectContext {
    var people:      Table<Person>     { return Table<Person>(context: self) }
    var departments: Table<Department> { return Table<Department>(context: self) }
}
```
##### Fetching

Say you have an `NSManagedObject` subclass type called `Person`, related to a `Department`. To get all of the `Person` entities as an array, use the following methods:

```swift
for person in context.people {
    print(person.firstName)
}
```

You can also skip some results:

```swift
let people = context.people.skip(3)
```

Or take some results only:

```swift
let people = context.people.skip(3).take(7)
```

Or, to return the results sorted by a property:

```swift
let sortedPeople = context.people.orderBy { $0.lastName }
```
Or, to return the results sorted by multiple properties:

```swift
let sortedPeople = context.people
    .orderBy { $0.lastName }
    .thenBy { $0.firstName }
```

Or, to return the results sorted by multiple properties, ascending or descending:

```swift
let sortedPeople = context.people
    .orderByDescending { $0.lastName }
    .thenByAscending { $0.firstName }
```

If you have a unique way of retrieving a single entity from your data store (such as via an identifier), you can use the `first` method:

```swift
if let person = context.people.first({ $0.identifier == 123 }) {
    print(person.name)
}
```

##### Filtering

You can filter the results using the `filter` method:

```swift
let filteredPeople = context.people.filter { $0.lastName == "Smith" }
```

You can combine multiple filters and other methods as well:

```swift
let filteredPeople = context.people
    .filter { $0.lastName == "Smith" }
    .filter { $0.firstName.beginsWith("J") }
    .orderBy { $0.lastName }
    .thenBy { $0.firstName }
```

Or:

```swift
let filteredPeople = context.people
    .filter { $0.lastName == "Smith" && $0.firstName.beginsWith("J") }
    .orderBy { $0.lastName }
    .thenBy { $0.firstName }
```

##### Counting

You can count entities in your persistent store using the `count` method.

```swift
let peopleCount = context.people.count()
```

Or:

```swift
let filteredPeopleCount = context.people.count { $0.lastName == "Smith" }
```

Or:

```swift
let filteredPeopleCount = context.people
    .filter { $0.lastName == "Smith" }
    .count()
```

#### Create, update, delete and save

##### Creating and updating entities

When you need to create a new instance of an Entity, use:

```swift
let person = context.people.create()
```

You can also create or get the first existing entity matching the criteria. If the entity does not exist, a new one is created and the specified attribute is assigned from the searched value automatically.

```swift
let person = context.people.firstOrCreated { $ 0.identifier == 123 }
```

##### Deleting entities

To delete a single entity:

```swift
if let person = context.people.first({ $0.identifier == 123 }) {
    context.people.delete(person)
}
```

To delete many entities:

```swift
context.departments.filter({ $0.people.count == 0 }).deleteAll()
```

##### Saving

You can save the data context in the end, after all changes were made.

```swift
container.performBackgroundTask { context in
    let person = context.people.firstOrCreated { $0.identifier == 9 }
    person.firstName = "Christopher"
    person.lastName = "Eccleston"
    person.additionalInfo = "The best Doctor ever!"

    do {
        try context.save()
    }
    catch {
        // do a nice error handling here
    }
}
```

#### Strongly-typed query attributes and ACDGen

Another important part of **AlecrimCoreData** is the use of strongly-typed query attributes.  A lot of boilerplate code is required to support strongly typed queries. With this in mind, the **ACDGen** tool was created. All you have to do is to point `ACDGen` to your managed object model and the source code for the entities is automatically generated, including the **AlecrimCoreData** query attributes if you want.

Using the generated strongly-typed query attributes is completely optional, but with them the experience with **AlecrimCoreData** is greatly improved. *The use of strongly-typed query attributes requires a project that has generated extensions of it's model classes using `ACDGen`.* 

**ACDGen** source code is avaible from the "ACDGen/Source" folder. There is a command line tool called **acdgenp** that can be built from the same project.

If you use **ACDGen**, consider setting `Manual/None` in your model as the selected option in Xcode for automatically entity code generation.

### Advanced use

OK. You can write code like this:

```swift
// No data access is made here.
let peopleInDepartments = container.viewContext.people
    .filter { $0.department << [dept1, dept2] }
    .orderBy { $0.firstName }
    .thenBy { $0.lastName }
        
let itemsPerPage = 10  

for pageNumber in 0..<5 {
    print("Page: \(pageNumber)")

    // No data access is made here either.
    let peopleInCurrentPage = peopleInDepartments
        .skip(pageNumber * itemsPerPage)
        .take(itemsPerPage)

    // Now is when the data is read from persistent store.
    for person in peopleInCurrentPage {
        print("\(person.firstName) \(person.lastName) - \(person.department.name)")
    }
}
```

But you can do even more with **AlecrimCoreData**. You are invited to read the code and discover more possibilities (and to help us to improve them and create new ones).

#### Advanced methods

There are methods for aggregating, asynchronous fetching in background and many others. You can read the **AlecrimCoreData** documentation at [http://cocoadocs.org/docsets/AlecrimCoreData](http://cocoadocs.org/docsets/AlecrimCoreData) for more information.

#### Ordering and filtering

You can order and filter entities not using the **AlecrimCoreData** query attributes at all. In this case you lose the strongly-typed attributes, but gain in flexibility. You can even mix the two approaches without any problem.

##### Ordering

You can order the entities using `NSSortDescriptor` instances:

```swift
let sortDescriptor: NSSortDescriptor = ...
let orderedPeople = context.people.sort(using: sortDescriptor)
```

Or:

```swift
let sd1: NSSortDescriptor = ...
let sd2: NSSortDescriptor = ...

let orderedPeople = context.people.sort(using: [sd1, sd2])
```

You can also use the `sortUsingAttributeName::` method:

```swift
let orderedPeople = context.people.sort(usingAttributeName: "lastName", ascending: true)
```

##### Filtering

You can filter entities using `NSPredicate` instances:

```swift
let predicate: NSPredicate = ...
let filteredPeople = context.people.filter(using: predicate)
```
## Using

### Minimum Requirements

- Swift 3.0
- Xcode 8.0
- macOS 10.12+ / iOS 9.0+ / tvOS 9.0+ / watchOS 2.0+

### Installation

#### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

CocoaPods 1.1.0+ is required to build AlecrimCoreData 5.0+.

To integrate **AlecrimCoreData** into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    # pod 'AlecrimCoreData', :git => 'https://github.com/Alecrim/AlecrimCoreData.git', :branch => 'develop'
    pod 'AlecrimCoreData', '~> 5.0'
end
```

Then, run the following command:

```bash
$ pod install
```

#### Manually

You can add AlecrimCoreData as a git submodule, drag the `AlecrimCoreData.xcodeproj` file into your Xcode project and add the framework product as an embedded binary in your application target.

---

## Contact
- [Vanderlei Martinelli](https://github.com/vmartinelli)

## License
**AlecrimCoreData** is released under an MIT license. See LICENSE for more information.

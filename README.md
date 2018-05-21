![AlecrimCoreData](https://raw.githubusercontent.com/Alecrim/AlecrimCoreData/master/AlecrimCoreData.png)

[![Language: Swift](https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platform](https://img.shields.io/cocoapods/p/AlecrimCoreData.svg?style=flat)](http://cocoadocs.org/docsets/AlecrimCoreData)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://raw.githubusercontent.com/Alecrim/AlecrimCoreData/develop/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/v/AlecrimCoreData.svg?style=flat)](http://cocoapods.org)
[![Apps](https://img.shields.io/cocoapods/at/AlecrimCoreData.svg?style=flat)](http://cocoadocs.org/docsets/AlecrimCoreData)
[![Author: vmartinelli](https://img.shields.io/badge/author-vmartinelli-blue.svg?style=flat)](https://www.linkedin.com/in/vmartinelli)

A powerful and elegant Core Data framework for Swift.

## Usage
Simple do that:

```swift
let query = persistentContainer.viewContext.people
    .where { \.city == "Piracicaba" }
    .orderBy { \.name }

for person in query.dropFirst(20).prefix(10) {
    print(person.name, person.address)
}
```

Or that:

```swift
persistentContainer.performBackgroundTask { context in
    let query = context.people
        .filtered(using: \.country == "Brazil" && \.isContributor == true)
        .sorted(by: .descending(\.contributionCount))
        .sorted(by: \.name)

    if let person = query.first() {
        print(person.name, person.email)
    }
}
```

After that:

```swift
import AlecrimCoreData

extension ManagedObjectContext {
    var people: Query<Person> { return Query(in: self) }
}

let persistentContainer = PersistentContainer()

```
And after your have created your matching managed object model in Xcode, of course. ;-)


## Legacy
In version 6 the framework was rewritten from scratch. **AlecrimCoreData** now uses key paths and it does not rely on generated (or written) custom attributes anymore. Also the **ACDGen** utility is no more. If your code depends on this, please use the previous versions.

Some well known features and functionalities may be reimplemented in a future release. No guarantees, though.

## Contribute
If you have any problems or need more information, please open an issue using the provided GitHub link.

You can also contribute by fixing errors or creating new features. When doing this, please submit your pull requests to this repository as I do not have much time to "hunt" forks for not submitted patches.

- master - The production branch. Clone or fork this repository for the latest copy.
- develop - The active development branch. [Pull requests](https://help.github.com/articles/creating-a-pull-request) should be directed to this branch.


## Contact the author
- [Vanderlei Martinelli](https://www.linkedin.com/in/vmartinelli)

## License
**AlecrimCoreData** is released under an MIT license. See LICENSE for more information.

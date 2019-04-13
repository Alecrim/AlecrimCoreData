![AlecrimCoreData](https://raw.githubusercontent.com/Alecrim/AlecrimCoreData/master/AlecrimCoreData.png)

[![Version](https://img.shields.io/badge/v7.0%20beta%201-blue.svg?label=version&style=flat)](https://github.com/Alecrim/AlecrimCoreData)
[![Language: swift](https://img.shields.io/badge/swift-v5.0-blue.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms](https://img.shields.io/badge/platforms-macOS%2C%20iOS%2C%20watchOS%2C%20tvOS-blue.svg?style=flat)](http://cocoadocs.org/docsets/AlecrimCoreData)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://raw.githubusercontent.com/Alecrim/AlecrimCoreData/develop/LICENSE)
[![Author: Vanderlei Martinelli](https://img.shields.io/badge/author-Vanderlei%20Martinelli-blue.svg?style=flat)](https://www.linkedin.com/in/vmartinelli)

A powerful and elegant Core Data framework for Swift.

## Usage

### Beta version. New docs soon...

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


## Contribute
If you have any problems or need more information, please open an issue using the provided GitHub link.

You can also contribute by fixing errors or creating new features. When doing this, please submit your pull requests to this repository as I do not have much time to "hunt" forks for not submitted patches.

- master - The production branch. Clone or fork this repository for the latest copy.
- develop - The active development branch. [Pull requests](https://help.github.com/articles/creating-a-pull-request) should be directed to this branch.


## Contact the author
- [Vanderlei Martinelli](https://www.linkedin.com/in/vmartinelli)

## License
**AlecrimCoreData** is released under an MIT license. See LICENSE for more information.

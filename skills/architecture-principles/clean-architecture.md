# Main goal
Make code with clear separation of concerns. You can achieve this separation by dividing the software into layers. Each has at least one layer for business rules, and another for interfaces.
System is organized into several layers(circles):
1. **Frameworks and Drivers** : External interfaces, DB, Devices, Web, UI
2. **Interface adapters**: Controllers, Presenters, Views
3. **Application Business Rules**: Use Cases
4. **Enterprise Business Rules**: Entities
Control flows from controllers into use cases and out to presenters, yet all source code dependencies point inward toward the use cases — an apparent contradiction at layer boundaries. This is resolved with the [Dependency Inversion Principle](./solid.md#dependency-inversion-principle-dip): instead of an inner-circle use case calling a presenter directly (which would violate the rule that inner circles never name outer ones), the use case calls an interface it owns — the Use Case Output — which the outer-layer presenter implements. The same dynamic-polymorphism technique is applied at every boundary: a high-level module defines the interface (like `DataStore` in the [Dependency Inversion Principle](./solid.md#dependency-inversion-principle-dip) section of solid.md) and a low-level module implements it, so source dependencies oppose the flow of control and The Dependency Rule holds regardless of which direction control travels.



## Design goals
To have the system with following attributes:
 - **Independent of Frameworks** The architecture does not depend on the existence of some library of feature laden software. This allows you to use such frameworks as tools, rather than having to cram your system into their limited constraints.
 - **Testable** The business rules can be tested without the UI, Database, Web Server, or any other external element.
 - **Independent of UI** The UI can change easily, without changing the rest of the system. A Web UI could be replaced with a console UI, for example, without changing the business rules.
 - **Independent of Database** You can swap out Oracle or SQL Server, for Mongo, BigTable, CouchDB, or something else. Your business rules are not bound to the database.
 - **Independent of any external agency**  In fact your business rules simply don’t know anything at all about the outside world.

## The Dependency Rule
**source code dependencies can only point inwards**.
Nothing in an inner circle can know anything at all about something in an outer circle. In particular, the name of something declared in an outer circle must not be mentioned by the code in the an inner circle. That includes, functions, classes. variables, or any other named software entity.

## Entities
Entities encapsulate Enterprise wide business rules. An entity can be an object with methods, or it can be a set of data structures and functions. It doesn’t matter so long as the entities could be used by many different applications in the enterprise.

## Use Cases
The software in this layer contains application specific business rules. It encapsulates and implements all of the use cases of the system. These use cases orchestrate the flow of data to and from the entities, and direct those entities to use their enterprise wide business rules to achieve the goals of the use case.
We do not expect changes in this layer to affect the entities. We also do not expect this layer to be affected by changes to externalities such as the database, the UI, or any of the common frameworks. This layer is isolated from such concerns.
We do, however, expect that changes to the operation of the application will affect the use-cases and therefore the software in this layer. If the details of a use-case change, then some code in this layer will certainly be affected.

## Use Case Output
The interface a use case owns and calls to hand back its result, instead of calling a presenter directly. The presenter implements it, so the dependency still points inward even though control flows outward.

## Interface Adapters
The software in this layer is a set of adapters that convert data from the format most convenient for the use cases and entities, to the format most convenient for some external agency such as the Database or the Web.
The Presenters, Views, and Controllers all belong in here. The models are likely just data structures that are passed from the controllers to the use cases, and then back from the use cases to the presenters and views.
Data is converted, in this layer, from the form most convenient for entities and use cases, into the form most convenient for whatever persistence framework is being used. i.e. The Database. No code inward of this circle should know anything at all about the database. 
Also in this layer is any other adapter necessary to convert data from some external form, such as an external service, to the internal form used by the use cases and entities.

## Controllers
Takes input from the outside world (an HTTP request, a CLI argument, a message off a queue) and translates it into the call a use case expects.

## Presenters
Takes the data a use case returns and reshapes it into whatever a View needs to render, without deciding how that rendering happens.

## Views
Presenting a data to a User, could be JSON for API, rendered html page or xml.

## Frameworks and Drivers.
The outermost layer is generally composed of frameworks and tools such as the Database, the Web Framework, etc. Generally you don’t write much code in this layer other than glue code that communicates to the next circle inwards.
This layer is where all the details go. The Web is a detail. The database is a detail. We keep these things on the outside where they can do little harm.

## What data crosses the boundaries.
Typically the data that crosses the boundaries is simple data structures. You can use basic structs or simple Data Transfer objects if you like. Or the data can simply be arguments in function calls. Or you can pack it into a hashmap, or construct it into an object. The important thing is that isolated, simple, data structures are passed across the boundaries. We don’t want to cheat and pass Entities or Database rows. We don’t want the data structures to have any kind of dependency that violates The Dependency Rule. So when we pass data across a boundary, it is always in the form that is most convenient for the inner circle.

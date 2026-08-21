# SOLID principles

## Single Responsibility Principle (SRP)
A class should have only one reason to change.

Violating SRP:
```golang
func (us *UserService) RegisterUser(username, password string) error {
  // Save user to database
  // Send confirmation email
  // Log registration event
  return nil
}
```
Following SRP:
```golang
type UserService struct {
  db Database
  email EmailService
  logger Logger
}

func (us *UserService) RegisterUser(username, password string) error {
  if err := us.db.SaveUser(username, password); err != nil {
    return err
  }
  if err := us.email.SendConfirmation(username); err != nil {
    return err
  }
  us.logger.Log("User registered: " + username)
  return nil
}
```

## Open/Closed Principle (OCP)
Software entities should be open for extension, but closed for modification.

Violating OCP:
```golang
func (p *PaymentProcessor) ProcessPayment(method string) {
  if method == "credit_card" {
    fmt.Println("Processing credit card payment")
  } else if method == "paypal" {
    fmt.Println("Processing PayPal payment")
  }
}
```

Following OCP: 
```golang
type PaymentMethod interface {
  Process()
}

type CreditCard struct {}
func (cc CreditCard) Process() { fmt.Println("Processing credit card payment") }

type PayPal struct {}
func (pp PayPal) Process() { fmt.Println("Processing PayPal payment") }

func (p PaymentProcessor) ProcessPayment(method PaymentMethod) {
  method.Process()
}
```

## Liskov Substitution Principle (LSP)
Subtypes must be substitutable for their base types.

Violating LSP:
```golang
type Resizable interface {
  SetWidth(w float64)
  SetHeight(h float64)
  Area() float64
}

type Rectangle struct {
  Width, Height float64
}
func (r *Rectangle) SetWidth(w float64)  { r.Width = w }
func (r *Rectangle) SetHeight(h float64) { r.Height = h }
func (r *Rectangle) Area() float64       { return r.Width * r.Height }

// Square satisfies Resizable, but must keep both sides equal,
// so SetWidth and SetHeight can't act independently like Rectangle's do.
type Square struct {
  Side float64
}
func (s *Square) SetWidth(w float64)  { s.Side = w }
func (s *Square) SetHeight(h float64) { s.Side = h }
func (s *Square) Area() float64       { return s.Side * s.Side }

func Resize(r Resizable, width, height float64) float64 {
  r.SetWidth(width)
  r.SetHeight(height)
  return r.Area() // expected width * height; a *Square silently returns height * height instead
}
```
Following LSP:

```golang
type Shape interface {
  Area() float64
}

type Rectangle struct {
  Width, Height float64
}
func (r Rectangle) Area() float64 { return r.Width * r.Height }

type Square struct {
  Side float64
}
func (s Square) Area() float64 { return s.Side * s.Side }

func PrintArea(shape Shape) {
  fmt.Printf("Area: %.2f\n", shape.Area())
}
```

## Interface Segregation Principle (ISP)
Clients should not be forced to depend on interfaces they do not use.

Violating ISP:

```golang
type Worker interface {
  Work()
  Eat()
  Sleep()
}
```

Following ISP:
```golang
type Worker interface { Work() }
type Eater interface { Eat() }
type Sleeper interface { Sleep() }
```

## Dependency Inversion Principle (DIP)
1. **High-level modules should not import anything from low-level modules. Both should depend on abstractions (e.g., interfaces).**
2. **Abstractions should not depend on details. Details (concrete implementations) should depend on abstractions.**

Define Interfaces for Dependencies
Instead of directly using concrete types, define interfaces that describe the behaviors your high-level modules need.
```golang
type DataStore interface {
    Save(data string) error
}
```
Implement Interfaces with Concrete Types
Create concrete types that implement these interfaces. These implementations are your low-level modules, but your high-level modules won’t depend on them directly.
```golang
type FileStore struct {}

func (fs FileStore) Save(data string) error {
    // Implementation to save data to a file
    return nil
}

type InMemoryStore struct {}

func (ims InMemoryStore) Save(data string) error {
    // Implementation to save data in memory
    return nil
}
```
Inject Dependencies
Instead of letting high-level modules create or choose which low-level module to use, “inject” the specific implementation of the interface they should use.

```golang
type Processor struct {
    store DataStore
}

func NewProcessor(store DataStore) *Processor {
    return &Processor{store: store}
}

func (p *Processor) Process(data string) error {
    // Use the DataStore to save data, without knowing the specific implementation
    return p.store.Save(data)
}
```


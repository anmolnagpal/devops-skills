# Language-Specific Security Quirks

> These are entry points, not exhaustive coverage. Think like a senior security researcher: consider the language's memory model, type system, standard library pitfalls, and historical CVE patterns.

---

## JavaScript / TypeScript
**Main Risks:** Prototype pollution, XSS, eval injection
```javascript
// UNSAFE: Prototype pollution
Object.assign(target, userInput)
// SAFE: Use null prototype or validate keys
Object.assign(Object.create(null), validated)

// UNSAFE: eval injection
eval(userCode)
// SAFE: Never use eval with user input
```
**Watch for:** `eval()`, `innerHTML`, `document.write()`, `__proto__`, prototype chain manipulation

---

## Python
**Main Risks:** Pickle deserialization, format string injection, shell injection
```python
# UNSAFE: Pickle RCE
pickle.loads(user_data)
# SAFE: Use JSON or validate source
json.loads(user_data)

# UNSAFE: Format string injection
query = "SELECT * FROM users WHERE name = '%s'" % user_input
# SAFE: Parameterized
cursor.execute("SELECT * FROM users WHERE name = %s", (user_input,))
```
**Watch for:** `pickle`, `eval()`, `exec()`, `os.system()`, `subprocess` with `shell=True`

---

## Java
**Main Risks:** Deserialization RCE, XXE, JNDI injection
```java
// UNSAFE: Arbitrary deserialization
ObjectInputStream ois = new ObjectInputStream(userStream);
Object obj = ois.readObject();

// SAFE: Use allowlist or JSON
ObjectMapper mapper = new ObjectMapper();
mapper.readValue(json, SafeClass.class);
```
**Watch for:** `ObjectInputStream`, `Runtime.exec()`, XML parsers without XXE protection, JNDI lookups

---

## C#
**Main Risks:** Deserialization, SQL injection, path traversal
```csharp
// UNSAFE: BinaryFormatter RCE
BinaryFormatter bf = new BinaryFormatter();
object obj = bf.Deserialize(stream);

// SAFE: Use System.Text.Json
var obj = JsonSerializer.Deserialize<SafeType>(json);
```
**Watch for:** `BinaryFormatter`, `JavaScriptSerializer`, `TypeNameHandling.All`, raw SQL strings

---

## PHP
**Main Risks:** Type juggling, file inclusion, object injection
```php
// UNSAFE: Type juggling in auth
if ($password == $stored_hash) { ... }
// SAFE: Use strict comparison
if (hash_equals($stored_hash, $password)) { ... }

// UNSAFE: File inclusion
include($_GET['page'] . '.php');
// SAFE: Allowlist pages
$allowed = ['home', 'about']; include(in_array($page, $allowed) ? "$page.php" : 'home.php');
```
**Watch for:** `==` vs `===`, `include/require`, `unserialize()`, `preg_replace` with `/e`, `extract()`

---

## Go
**Main Risks:** Race conditions, template injection, slice bounds
```go
// UNSAFE: Race condition
go func() { counter++ }()
// SAFE: Use sync primitives
atomic.AddInt64(&counter, 1)

// UNSAFE: Template injection
template.HTML(userInput)
// SAFE: Let template escape
{{.UserInput}}
```
**Watch for:** Goroutine data races, `template.HTML()`, `unsafe` package, unchecked slice access

---

## Ruby
**Main Risks:** Mass assignment, YAML deserialization, regex DoS
```ruby
# UNSAFE: Mass assignment
User.new(params[:user])
# SAFE: Strong parameters
User.new(params.require(:user).permit(:name, :email))

# UNSAFE: YAML RCE
YAML.load(user_input)
# SAFE: Use safe_load
YAML.safe_load(user_input)
```
**Watch for:** `YAML.load`, `Marshal.load`, `eval`, `send` with user input, `.permit!`

---

## Rust
**Main Risks:** Unsafe blocks, FFI boundary issues, integer overflow in release
```rust
// CAUTION: Unsafe bypasses safety
unsafe { ptr::read(user_ptr) }

// CAUTION: Release integer overflow
let x: u8 = 255;
let y = x + 1; // Wraps to 0 in release!
// SAFE: Use checked arithmetic
let y = x.checked_add(1).unwrap_or(255);
```
**Watch for:** `unsafe` blocks, FFI calls, integer overflow in release builds, `.unwrap()` on untrusted input

---

## Swift
**Main Risks:** Force unwrapping crashes, Objective-C interop
```swift
// UNSAFE: Force unwrap on untrusted data
let value = jsonDict["key"]!
// SAFE: Safe unwrapping
guard let value = jsonDict["key"] else { return }
```
**Watch for:** force unwrap (`!`), `try!`, ObjC bridging, `NSSecureCoding` misuse

---

## Kotlin
**Main Risks:** Null safety bypass, Java interop, serialization
```kotlin
// UNSAFE: Platform type from Java
val len = javaString.length // NPE if null
// SAFE: Explicit null check
val len = javaString?.length ?: 0
```
**Watch for:** Java interop nulls (`!` operator), reflection, serialization, platform types

---

## C / C++
**Main Risks:** Buffer overflow, use-after-free, format string
```c
// UNSAFE: Buffer overflow
char buf[10]; strcpy(buf, userInput);
// SAFE: Bounds checking
strncpy(buf, userInput, sizeof(buf) - 1);

// UNSAFE: Format string
printf(userInput);
// SAFE: Always use format specifier
printf("%s", userInput);
```
**Watch for:** `strcpy`, `sprintf`, `gets`, pointer arithmetic, manual memory management, integer overflow

---

## Shell (Bash)
**Main Risks:** Command injection, word splitting, globbing
```bash
# UNSAFE: Unquoted variables
rm $user_file
# SAFE: Always quote
rm "$user_file"

# UNSAFE: eval
eval "$user_command"
# SAFE: Never eval user input
```
**Watch for:** Unquoted variables, `eval`, backticks, `$(...)` with user input, missing `set -euo pipefail`

---

## SQL (All Dialects)
**Main Risks:** Injection, privilege escalation, data exfiltration
```sql
-- UNSAFE: String concatenation
"SELECT * FROM users WHERE id = " + userId

-- SAFE: Parameterized query (use prepared statements in ALL cases)
```
**Watch for:** Dynamic SQL, `EXECUTE IMMEDIATE`, stored procedures with dynamic queries, privilege grants

---

## Other Languages

| Language | Top Risk | Watch For |
|----------|----------|-----------|
| Scala | XXE, serialization | XML parsing, `Serializable`, Java interop |
| R | Code injection | `eval()`, `parse()`, `source()`, `system()` |
| Perl | Regex DoS, open() injection | Two-arg `open()`, backticks, `eval` |
| Lua | Sandbox escape | `loadstring`, `os.execute`, `io` library |
| Elixir | Atom exhaustion | `String.to_atom`, `Code.eval_string` |
| Dart/Flutter | Insecure storage | `SharedPreferences` for secrets, platform channels |
| PowerShell | Command injection | `Invoke-Expression`, `& $userVar` |

---

## Deep Security Analysis Mindset

When reviewing any language, think like a senior security researcher:

1. **Memory Model** — Managed vs manual? GC pauses exploitable?
2. **Type System** — Weak typing = type confusion attacks
3. **Serialization** — Every language has its pickle/Marshal equivalent. All are dangerous
4. **Concurrency** — Race conditions, TOCTOU, atomicity failures
5. **FFI Boundaries** — Native interop is where type safety breaks down
6. **Standard Library** — Historic CVEs in std libs (Python urllib, Java XML, Ruby OpenSSL)
7. **Package Ecosystem** — Typosquatting, dependency confusion, malicious packages
8. **Runtime Behavior** — Debug vs release differences (Rust overflow, C++ assertions)
9. **Error Handling** — How does the language fail? Silently? With stack traces? Fail-open?

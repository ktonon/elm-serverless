# Release Notes

## 4.0.0

* `Conn` and `Plug` are now opaque.
* `Plug` has been greatly simplified.
* Simpler pipelines, just `|>` chains of `Conn -> Conn` functions. However pipelines can still send responses and terminate the connection early.
* A single update function (just like an Elm SPA).
* Proper JavaScript interop.

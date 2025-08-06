# gridsim
Toy power grid simulation suite

# Building
Simply run `zig build` in the root directory of the repo.  
*Note: This project is built using Zig version 0.14.0. It may not compile using earlier or later versions.*

# Usage
## Specification
Simulation parameters are specified by a `simulation.Spec`. This object can be defined in and loaded from a [ZON](https://github.com/ziglang/zig/pull/20271) file (see `examples/small_spec.zon`).

# TODO
- [ ] Detailed README
- [ ] Documentation
  - [ ] `power` module
  - [ ] `simulation` module
- [ ] Comprehensive tests
  - [ ] `power` module
  - [ ] `simulation` module
  - [ ] `utils.convert` function
- [ ] Python bindings
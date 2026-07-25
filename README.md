# Homebrew Chaste Dependencies

Homebrew formulae for installing the dependencies for [Chaste](https://chaste.github.io/), a simulation package for
computational biology.

## How do I install these formulae?

```sh
brew install kwabenantim/chaste/chaste-dependencies
```

Or

```sh
brew tap kwabenantim/chaste
brew install chaste-dependencies
```

## What is in this tap?

Chaste needs MPI-enabled variants of VTK and HDF5. Homebrew-core currently provides an `hdf5-mpi` variant of `hdf5`, but
no `vtk-mpi` variant of `vtk`. VTK links against HDF5 so the `vtk-mpi` variant should link against the parallel
`hdf5-mpi` variant from homebrew-core to avoid conflicts with the main `hdf5`. Two VTK dependencies (`netcdf` and
`cgns`) also link against HDF5 and need to do the same. Three of the tap's four variants exist for that reason:

| Formula      | Variant of | Built against                        |
| ------------ | ---------- | ------------------------------------ |
| `vtk-mpi`    | `vtk`      | `hdf5-mpi`, `netcdf-mpi`, `cgns-mpi` |
| `netcdf-mpi` | `netcdf`   | `hdf5-mpi`                           |
| `cgns-mpi`   | `cgns`     | `hdf5-mpi`                           |

Each of those three conflicts with its homebrew-core counterpart, in the same way `hdf5-mpi` conflicts with `hdf5`.
Installing one will fail while the serial version is present. To replace pre-installed serial versions:

```sh
brew uninstall --ignore-dependencies vtk netcdf cgns hdf5 || true
brew install kwabenantim/chaste/vtk-mpi
```

Chaste also partitions meshes through Scotch's ParMETIS-compatible interface. Homebrew-core builds `scotch` with
`-DINSTALL_METIS_HEADERS=OFF`, so it ships no `metis.h` or `parmetis.h`. The fourth variant turns them back on:

| Formula           | Variant of | Difference                   |
| ----------------- | ---------- | ---------------------------- |
| `scotch-parmetis` | `scotch`   | `-DINSTALL_METIS_HEADERS=ON` |

This one is keg-only instead of conflicting with its counterpart. Its `metis.h` would collide with the `metis` formula,
and `metis` cannot be dropped because `petsc` requires it. Nothing is linked into the prefix, so point at the keg:

```sh
brew --prefix kwabenantim/chaste/scotch-parmetis
```

Everything else Chaste needs comes from homebrew-core:

- `boost`
- `cmake`
- `hdf5-mpi`
- `petsc`
- `sundials`
- `xerces-c`
- `xsd`

The `chaste-dependencies` meta-formula installs that list plus `vtk-mpi` and `scotch-parmetis`, and provides a
`chaste-dependencies` command that prints the name, version and prefix of each.

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

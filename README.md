# Chaste Dependencies

Homebrew formulae for [Chaste](https://chaste.github.io/), a simulation package
for computational biology.

## How do I install these formulae?

`brew install kwabenantim/chaste/chaste-dependencies`

Or `brew tap kwabenantim/chaste` and then `brew install chaste-dependencies`.

## What is in this tap?

Chaste needs an MPI-enabled build of VTK. VTK links against HDF5, and so do two
of its dependencies, so all three have to agree on which HDF5 they use. This tap
carries only those parallel variants:

| Formula      | Variant of | Built against            |
| ------------ | ---------- | ------------------------ |
| `vtk-mpi`    | `vtk`      | `hdf5-mpi`, `netcdf-mpi`, `cgns-mpi` |
| `netcdf-mpi` | `netcdf`   | `hdf5-mpi`               |
| `cgns-mpi`   | `cgns`     | `hdf5-mpi`               |

Each conflicts with its homebrew-core counterpart, in the same way `hdf5-mpi`
conflicts with `hdf5`. Installing one will fail while the serial version is
present:

```
brew uninstall --ignore-dependencies vtk netcdf cgns hdf5
brew install kwabenantim/chaste/vtk-mpi
```

Everything else Chaste needs comes from homebrew-core: `boost`, `cmake`,
`hdf5-mpi`, `petsc`, `scotch`, `sundials`, `xerces-c` and `xsd`. The
`chaste-dependencies` formula installs that list plus `vtk-mpi`, and provides a
`chaste-dependencies` command that prints the name, version and prefix of each.

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

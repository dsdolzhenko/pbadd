# pbadd

Add files to the clipboard from CLI as if they would be copied with Finder.

## Motivation

The built-in `pbcopy` command only works with text.
If you want to copy an image, PDF, or any other file type to the clipboard from the terminal, you're out of luck.

`pbadd` fills this gap by enabling you to copy any file to the clipboard, just like when you copy files in Finder.
You can then paste these files into any application that accepts them - paste images into documents, PDFs into emails, or any file into chat applications.

## Installation

### Prerequisites

- macOS 11.0 or later (Big Sur or newer)
- Xcode Command Line Tools or full Xcode installation
- Make

### Install

```bash
make && sudo make install
```

This will build the `pbadd` executable and install it to `/usr/local/bin`.

To install to a different location:

```bash
make && make install PREFIX=/your/custom/path
```

### Uninstall

```bash
make uninstall
```

or

```
make uninstall PREFIX=/your/custom/path
```

## Usage

```bash
# Add files to the clipboard
pbadd /path/to/file another/file

# Display help
pbadd -h
pbadd --help
```

## License

The project is licensed under [the MIT license](LICENSE.txt).

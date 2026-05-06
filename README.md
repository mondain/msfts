# MOQT Streaming Format Transport Stream

This is the working area for the individual Internet-Draft, "MPEG-2 Transport
Stream Packaging for Media Over QUIC Transport".

* [Datatracker Page](https://datatracker.ietf.org/doc/draft-gregoire-moq-msfts)
* [Individual Draft](https://datatracker.ietf.org/doc/html/draft-gregoire-moq-msfts)


## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

Contributions can be made by creating pull requests.
The GitHub interface supports creating pull requests using the Edit button.


## Command Line Usage

Formatted text and HTML versions of the draft can be built using `make`.

```sh
$ make
```

Command line usage requires that you have the necessary software installed. See
[the instructions](https://github.com/martinthomson/i-d-template/blob/main/doc/SETUP.md).

## Submission Checklist

Run the practical pre-submit checks:

```sh
$ make check-submission
```

This runs:

```sh
$ make latest lint
$ make idnits idnits_mode=forgive-checklist
```

Expected residual warnings that can be tooling/environment related:

* `POSSIBLE_DOWNREF` for active Internet-Draft references when status lookup fails.
* `LINE_PI` from generated `<?line ...?>` processing instructions in markdown-to-XML workflows.

For a printed checklist in terminal:

```sh
$ make submission-checklist
```

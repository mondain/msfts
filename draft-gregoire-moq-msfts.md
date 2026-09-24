---
title: "MPEG-2 Transport Stream Packaging for MOQT"
abbrev: "MOQT MPEG-2 TS Packaging"
category: info

docname: draft-gregoire-moq-msfts-latest
submissiontype: IETF
number:
date:
consensus: false
v: 3
area: "Applications and Real-Time"
workgroup: "Media Over QUIC"
keyword:
 - MOQ
 - MOQTransport
 - MPEG-2 Transport Stream
 - M2TS
 - MSF
venue:
  group: "Media Over QUIC"
  type: "Working Group"
  mail: "moq@ietf.org"
  arch: "https://mailarchive.ietf.org/arch/browse/moq/"
  github: "mondain/msfts"
  latest: "https://mondain.github.io/msfts/draft-gregoire-moq-msfts.html"

author:
 -
    fullname: Paul Gregoire
    organization: Red5
    email: paul@red5.net
 -
    fullname: Gwendal Simon
    organization: Quortex
    email: gwendal.simon@quortex.io

normative:
  LOC: I-D.draft-ietf-moq-loc
  MOQTransport: I-D.draft-ietf-moq-transport
  MSF: I-D.draft-ietf-moq-msf-01
  ISO138181:
    title: "Information technology - Generic coding of moving pictures and associated audio information: Systems"
    author:
      org: ISO/IEC
    seriesinfo:
      ISO/IEC: 13818-1
    date: 2023
  BASE64: RFC4648
  SCTE35:
    title: "Digital Program Insertion Cueing Message"
    author:
      org: Society of Cable Telecommunications Engineers
    seriesinfo:
      ANSI/SCTE: 35 2023r1
    date: 2023-11

informative:
  ISO138189:
    title: "Information technology - Generic coding of moving pictures and
            associated audio information - Part 9: Extension for real time
            interface for systems decoders"
    author:
      org: ISO/IEC
    seriesinfo:
      ISO/IEC: 13818-9
    date: 1996
  TR101290:
    title: "Digital Video Broadcasting (DVB); Measurement guidelines for DVB
            systems"
    author:
      org: European Telecommunications Standards Institute
    seriesinfo:
      ETSI TR: 101 290 V1.4.1
    date: 2020-06
  SCTE35Timeline: I-D.draft-wilaw-moq-scte35-event-timeline
  DVBSI:
    title: "Digital Video Broadcasting (DVB); Specification for Service
            Information (SI) in DVB systems"
    author:
      org: European Telecommunications Standards Institute
    seriesinfo:
      ETSI EN: 300 468 V1.19.1
    date: 2025-02
  ATSCPSIP:
    title: "ATSC Standard: Program and System Information Protocol for
            Terrestrial Broadcast and Cable"
    author:
      org: Advanced Television Systems Committee
    seriesinfo:
      ATSC: A/65:2013
    date: 2013
  SecureObjects: I-D.draft-ietf-moq-secure-objects

--- abstract

This document extends the MOQT Streaming Format (MSF) catalog by defining the
"mpeg2ts" packaging value for carrying MPEG-2 Transport Stream and M2TS source
packets over MOQT. It defines catalog-extension fields for transport-stream
track description and specifies subscriber behavior for joining, switching,
and validating packetized streams.

--- middle

# Introduction {#introduction}

MPEG-2 Transport Stream MOQT Streaming Format (MSFTS) is an extension of the
MOQT Streaming Format (MSF) {{MSF}} that delivers MPEG-2 Transport Stream (TS)
{{ISO138181}} content over MOQT {{MOQTransport}}. MSFTS retains the scope,
capabilities, and features of MSF, including the catalog format, the timeline,
and alternate rendition switching.

MSFTS defines two families of Object payload. A track of the first family
carries whole TS source packets, either 188 or 192 octets each. It serves a
subscriber that feeds equipment expecting a transport stream, for example an
Integrated Receiver Decoder (IRD). A track of the second family carries the
units of one elementary stream: a frame in an LOC track {{LOC}}, or a
Packetized Elementary Stream (PES) packet or a section in an mpeg2ts track
({{es-units-carriage}}, {{media-frames-carriage}}). It serves a subscriber
that feeds a decoder. A subscriber that outputs a transport stream keeps the
packets of the first family. For the second family it builds the packets, the
signaling, and the timing itself.

This document describes version 2 of the MSFTS packaging format.

# MSF Extension {#msf-extension}

All specifications, requirements, and terminology defined in {{MSF}} apply to
implementations of this extension unless explicitly noted otherwise in this
document.

MSFTS uses the Low Overhead Media Container (LOC) {{LOC}} packaging defined in
{{MSF}} for the media frames of a program ({{media-packaging}}). For an
mpeg2ts track, this document defines the Object payload rules that LOC would
otherwise supply ({{object-payload-format}}).

This document uses two unrelated version numbers. The catalog `version` field
carries the MSF revision. The MSFTS format version given in {{introduction}}
identifies this packaging specification and never appears in a catalog. A
catalog conforming to this document MUST set `version` as {{MSF}} requires.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

This document uses the following abbreviations from {{ISO138181}}: Packet
Identifier (PID), Program Association Table (PAT), Program Map Table (PMT),
Conditional Access Table (CAT), Program Clock Reference (PCR), Packetized
Elementary Stream (PES), Program Specific Information (PSI), Presentation Time
Stamp (PTS), and Decoding Time Stamp (DTS).

The following terms are used throughout this document:

TS packet:
: A 188-octet MPEG-2 Transport Stream packet as defined by {{ISO138181}}.

M2TS source packet:
: A 192-octet packet consisting of a four-octet source-packet timestamp
  followed by a 188-octet TS packet.

Source packet:
: Either a TS packet or an M2TS source packet. The catalog signals which of
  the two a track carries.

Subscriber:
: The MOQT endpoint that subscribes to a track and receives its Objects, as
  defined by {{MOQTransport}}. A subscriber operates on MOQT Objects and
  produces the reconstructed packet stream.

Receiver:
: The equipment that consumes the reconstructed packet stream, for example an
  Integrated Receiver Decoder (IRD). A receiver operates on source packets and
  needs no knowledge of MOQT. One implementation can act as both a subscriber
  and a receiver.

Random access point:
: A point in the packet stream at which a receiver can begin decoding after
  receiving the applicable transport-stream tables and decoder initialization.

Single-program transport stream:
: A transport stream whose PAT lists exactly one program.

Multi-program transport stream (MPTS):
: A transport stream whose PAT lists two or more programs.

# Scope

The purpose of MSFTS is to carry an MPEG-2 Transport Stream over
{{MOQTransport}} without changing the transport stream itself.
Interoperability implies that:

* An original publisher can map an incoming transport stream into MOQT Objects
  and Groups, describe it in an MSF catalog, and announce it to an MOQT relay.
* An MOQT relay can cache and propagate the tracks without parsing the
  transport stream.
* A final subscriber can parse the catalog, subscribe to the tracks it needs,
  reconstruct the packet stream, and pass it to a transport-stream decoder.

A subscriber needs to know how the publisher produced each track: the unit
that its Objects carry, how the publisher derived the track, which
program or elementary stream the track carries, and where the timing reference
lives. MSFTS defines the catalog signaling that carries those decisions from
the publisher to the subscriber.

# Media Packaging {#media-packaging}

This document describes tracks of two MSF packagings. A track whose Objects
carry decoded media frames MUST set the MSF `packaging` field to "loc" and
follow {{LOC}}, so a subscriber that knows nothing of MPEG-2 systems plays it.
A track whose Objects carry TS source packets, PES packets, or sections MUST
set `packaging` to "mpeg2ts", and it carries a single ordered stream of either
TS source packets or the units that `mpeg2tsEsPayload`
({{mpeg2ts-es-payload}}) names.

The track fields defined in {{track-fields}} apply to a track of either
packaging.

## Object Payload Format {#object-payload-format}

The Object payload of a track depends on what the track carries. This section
gives the three forms.

### Source Packets {#payload-source-packets}

On an mpeg2ts track that declares no `mpeg2tsEsPayload`, the payload of each
MOQT Object is a sequence of whole source packets:

~~~ ascii-art
+===============+===============+=====+===============+
| source packet | source packet | ... | source packet |
+===============+===============+=====+===============+
~~~
{: title="Object payload of an mpeg2ts track"}

Every source packet on a track has the same size, either 188 or 192 octets, as
`mpeg2tsPacketSize` ({{mpeg2ts-packet-size}}) declares. An Object payload MUST
contain only whole source packets, so its length is always a multiple of
`mpeg2tsPacketSize`. A subscriber MUST reject an Object that breaks this rule.

A subscriber reconstructs the packet stream by concatenating the source
packets from received Objects in ascending Group ID and Object ID order. A
subscriber that skips or fails to receive an Object MUST consider the
reconstructed packet stream discontinuous at that point until it reaches a
subsequent random access point.

Object boundaries are packaging boundaries and do not change TS semantics.
Continuity counters, adaptation fields, PCR, PTS, DTS, PSI, and other TS syntax
remain inside the source packets.

TS semantics cover a delivery schedule as well as syntax. The PCR values in a
stream state when each TS byte is meant to reach a decoder. Section 2.4.2 of
{{ISO138181}} expresses the buffer constraints of a reference decoder against
that schedule, {{ISO138189}} gives the tolerance within which a delivered stream
matches it, and {{TR101290}} defines the limits that a DVB deployment must
meet. Object boundaries do not alter the schedule that a stream describes, and
{{pcr-timing}} covers how MOQT delivery relates to it.

In an unmodified mode ({{mpeg2ts-mode}}), a publisher MUST NOT modify the
continuity counter of any source packet and MUST NOT remap PIDs.
{{carriage-modes}} defines the modifications a publisher may make in the other
modes.

### PES Packets and Sections {#payload-units}

When `mpeg2tsEsPayload` ({{mpeg2ts-es-payload}}) is present, each Object
carries exactly one unit of the elementary stream or the table that
`mpeg2tsEsPid` names. A "pes" Object carries one complete PES packet, header
included, so the PTS, the DTS, and every other PES header field reach the
subscriber. A "section" Object carries one complete section, header and CRC
included, which `section_length` delimits.

A subscriber MUST reject an Object that carries more than one unit, or part of
one. The units carry no continuity counter, no adaptation field, and no PCR,
and {{es-units-carriage}} states what a subscriber regenerates.

### Media Frames {#payload-frames}

A track whose `packaging` is "loc" carries one media frame per Object, and
{{LOC}} defines the payload. The fields of {{track-fields}} record where the
elementary stream sat in the source transport stream, and they change neither
the payload nor its framing.

## Group Boundaries {#group-boundaries}

For live single-program tracks, a publisher SHOULD start a new MOQT Group at
each point where the Group content is independently decodable without
reference to prior Groups. A publisher SHOULD place a random access point at
the first Object of each Group, and the Group then includes the PAT and PMT
packets required for program demultiplexing.

For a track carrying a whole multiplex, Group boundary placement depends on
whether the publisher can identify random access points across the multiplex.
A publisher that can identify them MAY align Group boundaries to those points
and set `mpeg2tsRandomAccess` to true.

When `mpeg2tsRandomAccess` ({{mpeg2ts-random-access}}) is true, the first
Object in every Group MUST provide a valid random access starting point for
that Group.

## Source Handling and Carriage Modes {#carriage-modes}

The required `mpeg2tsMode` field ({{mpeg2ts-mode}}) names what a track carries
and how the publisher derived it. {{carriage-table}} gives the six values, and
the sections that follow define each one.

| mpeg2tsMode | packaging | mpeg2tsPacketSize | mpeg2tsEsPid | mpeg2tsEsPayload |
|:==========|:==========|:==========|:==========|:=========|
| unmodified-program | mpeg2ts | present | absent | absent |
| unmodified-multiplex | mpeg2ts | present | absent | absent |
| per-program | mpeg2ts | present | absent | absent |
| es-packets | mpeg2ts | present | present | absent |
| es-units | mpeg2ts | absent | present | present |
| media-frames | loc | absent | present | absent |
{: #carriage-table title="Fields that each mode requires"}

A subscriber MUST treat a track that breaks {{carriage-table}} as invalid.

### Unmodified Program {#unmodified-program-carriage}

The publisher forwards the source packets of a single-program transport stream
without modification: no program selection, no packet identifier remap, no PAT
or PMT rewrite, and no insertion or removal of null packets. A subscriber can
reconstruct the source stream byte-for-byte.

A publisher SHOULD verify that its pipeline preserves every source packet
before it declares this mode.

The catalog does not need to describe the program, because the PAT and PMT
reach the subscriber unaltered within one PSI repetition cycle.

### Unmodified Multiplex {#unmodified-multiplex-carriage}

The publisher forwards the source packets of a multi-program transport stream,
under the rules of {{unmodified-program-carriage}}, and emits every packet as
received. Because the publisher selects no program, `mpeg2tsProgramNumber` and
`mpeg2tsPcrPid` MUST be absent.

### Per-Program {#per-program-carriage}

The publisher carries one program that it derived from the source. It has
changed the source stream to do so, for example by selecting the program,
filtering packets, rewriting the PAT or the PMT, or adding or removing null
packets.

A publisher deriving a per-program track SHOULD drop every source packet
except:

* PAT packets (PID 0x0000), rewritten to list only the program present in
  this track.
* PMT packets for the selected program, on the PID that the rewritten PAT
  lists.
* Packets on any PID that the selected program's PMT lists, including the PCR
  PID, the PIDs of all elementary streams, and the PIDs that any
  CA_descriptor references.
* Packets carrying the service information (SI) tables that the publisher
  retains, if any.
* Conditional access packets, including the CAT on PID 0x0001, which no PMT
  lists.
* Null packets (PID 0x1FFF), which the publisher MAY drop or retain.

A publisher that rewrites the PAT and the PMT SHOULD emit them at least as
often as the source stream did.

A publisher filtering a scrambled transport stream MUST retain the conditional
access packets required for descrambling. Conditional access integration is
application-specific and outside the scope of this document. A CAT carried
from a multi-program source references the entitlement management streams of
every program in the multiplex, so a publisher SHOULD rewrite it to leave only
the entries for the carried program.

The `mpeg2tsProgramNumber` field ({{mpeg2ts-program-number}}) SHOULD be
present on per-program tracks to identify the program carried. When multiple
per-program tracks are derived from the same MPTS source, the publisher SHOULD
use the MSF `altGroup` field if the programs are alternate renditions of the
same content, and SHOULD publish programs that are independent services as
separate tracks.

Removing null packets changes the inter-packet byte spacing that
constant-bit-rate receivers use to recover the mux clock. A subscriber wishing
to reconstruct a constant-bit-rate output stream cannot derive the original
rate from the stream alone, so a publisher declares it with `mpeg2tsMuxRate`
({{mpeg2ts-mux-rate}}).

A publisher that retains SI tables SHOULD declare their PIDs using
`mpeg2tsSiPids` ({{mpeg2ts-si-pids}}), so that a subscriber can tell which
tables are present without inspecting the packet stream. The declaration is
needed because no PMT lists the SI PIDs, so the packet filter defined at the
start of this section drops these tables unless the publisher retains them
deliberately. A track without them has no service identity, no event schedule,
and no broadcast time, which a publisher targeting broadcast or IRD reception
SHOULD preserve.

Digital Video Broadcasting (DVB) and the Advanced Television Systems Committee
(ATSC) define different SI tables and place them on different PIDs. {{DVBSI}}
specifies the DVB tables and {{ATSCPSIP}} specifies the ATSC Program and
System Information Protocol. A publisher SHOULD retain the tables that the
target standard requires.

SI tables that describe individual services carry entries for every program in
a multiplex, so a publisher deriving a per-program track SHOULD rewrite them
to leave only the entries for the carried program.

### ES-Packets {#es-level-carriage}

When `mpeg2tsEsPid` ({{mpeg2ts-es-pid}}) is present, the track carries a
single elementary stream or signaling table. The track payload contains only
the packets or the units of the PID that `mpeg2tsEsPid` identifies, and it MUST
NOT contain null packets.

A publisher using ES-level carriage SHOULD publish the program signaling as two
further tracks, one carrying the PAT and one carrying the PMT of the program
({{mpeg2ts-es-pid}}). The tables then reach a subscriber as the publisher
produced them, with their descriptors and their stream types intact. The
publisher SHOULD rewrite the PAT to list only the program that it carries.

When `mpeg2tsPcrPid` equals `mpeg2tsEsPid`, the track carries the PCR and
provides the timing reference for the program. When `mpeg2tsPcrPid` identifies
a different PID, another track carries the PCR, and a subscriber that needs
PCR timing MUST subscribe to that track. {{pcr-timing}} applies to the track
that carries the PCR.

A publisher producing multiple ES-level media tracks for the same program
SHOULD align Group boundaries across those tracks so that matching Group
numbers correspond to the same presentation position. Elementary streams have
different frame durations, so exact alignment is not always possible. The
recommendation does not apply to a track carrying a table, which has no
presentation position.

A subscriber that combines ES-level tracks and outputs a TS MUST subscribe to
the PAT track and to the PMT track of the program
when the catalog offers them. It MUST emit both tables, and it MUST repeat
them at the interval that the standard governing its output requires, for
example {{TR101290}} for a DVB deployment. When it carries a subset of the
elementary streams that the PMT lists, it MUST remove the entries for the
streams it does not carry, correct the CRC of the section, and increment its
`version_number`. When the tracks carry source packets, it MUST take the PCR
from the track whose `mpeg2tsEsPid` equals the `mpeg2tsPcrPid` that those
tracks declare.

A subscriber that finds no PAT track and no PMT track cannot produce a
conformant PMT, because the catalog carries no stream type for an elementary
stream. Such a subscriber MUST NOT present its output as a conformant
transport stream.

An ES-level track carries no CAT, so it carries no conditional access
association between a scrambled elementary stream and the streams that key it.
A publisher also cannot identify random access points in a payload it cannot
decrypt, so it cannot set `mpeg2tsRandomAccess` to true. A publisher carrying
a scrambled source SHOULD use unmodified or per-program carriage.

### ES-Units {#es-units-carriage}

Each Object carries either one PES packet or one section of the PID that
`mpeg2tsEsPid` names ({{payload-units}}). A publisher sets `mpeg2tsEsPayload`
({{mpeg2ts-es-payload}}) to "pes" for an elementary stream it did not decode,
so the PTS, the DTS, and every other PES header field survive without the
catalog describing them. It sets the field to "section" for a table, including
the PAT and the PMT that {{es-level-carriage}} recommends.

A track in this mode MUST NOT carry a scrambled elementary stream.

A subscriber that outputs a transport stream from tracks in this mode, or in
the mode of {{media-frames-carriage}}, synthesizes what those tracks no longer
carry. It MUST generate the continuity counters, the adaptation fields, and the
PCR of its output, and it MUST packetize each unit and each media frame onto
the PID that `mpeg2tsEsPid` records. It MAY use `mpeg2tsMuxRate`
({{mpeg2ts-mux-rate}}) as the rate to pad toward. The reconstructed stream
carries neither the byte schedule nor the packet layout of the source, so a
deployment that needs either one uses an unmodified mode or
{{per-program-carriage}}.

### Media Frames {#media-frames-carriage}

The publisher decoded the elementary stream, and each Object carries one media
frame in an LOC track {{LOC}}, with the timestamp and the decoder configuration
that LOC and MSF define. The track carries `mpeg2tsEsPid` to record the PID
that the elementary stream held, and `mpeg2tsProgramNumber` to record the
program. A subscriber that only plays the media needs nothing else from this
document.

A track in this mode MUST NOT carry a scrambled elementary stream. A subscriber
that outputs a transport stream follows {{es-units-carriage}}.

## PCR and Timing {#pcr-timing}

The PCR is carried inside adaptation fields of transport-stream packets as
defined by {{ISO138181}}. MOQT Object and Group boundaries are packaging
boundaries and do not alter PCR continuity within a track.

A publisher MUST NOT introduce a PCR discontinuity within a single MOQT Group.
A publisher that introduces a PCR discontinuity between consecutive MOQT
Groups MUST signal it by setting the discontinuity_indicator bit
({{ISO138181}}, Section 2.4.3.5) in the adaptation field of the first TS
packet carrying PCR in the new Group. The PCR base field wraps around during
long-running streams, and a wrap is not a discontinuity: a publisher MUST NOT
signal one when the PCR base wraps.

A subscriber cannot recover the source mux clock from the rate at which
packets arrive. MOQT delivers whole Objects, and a relay can serve them from
its cache as fast as the link allows, so arrival timing carries no information
about the source. Conformance to the delivery schedule is therefore a property
of how a subscriber delivers its reconstructed packet stream to a receiver,
and not of the carriage between publisher and subscriber.

## Egress Timing {#egress-timing}

The PCR values of a reconstructed packet stream describe a delivery schedule.
The stream meets that schedule only if the subscriber hands each source packet
to the receiver at the time the schedule states.

A subscriber whose receiver recovers its clock from packet arrival MUST
deliver the source packets on a schedule consistent with the PCR values they
carry. That subscriber SHOULD meet the PCR repetition and accuracy limits of
the standard governing the receiver, given by {{TR101290}} for a DVB
deployment. Where the receiver expects a constant bit rate, the subscriber
SHOULD use `mpeg2tsMuxRate` ({{mpeg2ts-mux-rate}}) as the stuffing target. A
stuffing target does not reproduce the source schedule. Reproducing it
requires timing information that this document does not define.

## Splice Signaling {#splice-signaling}

An mpeg2ts track carries SCTE-35 {{SCTE35}} splice information in band, as
splice_info_section() messages on the PID that `mpeg2tsScte35Pid`
({{mpeg2ts-scte35-pid}}) declares. This document does not specify SCTE-35
processing.

A publisher MAY also publish the same splice events out of band, on an MSF
Event Timeline track. {{SCTE35Timeline}} defines the event type identifiers
and the payload format for that track. A subscriber can then read splice
events without parsing the packet stream.

# Catalog {#catalog}

The MSF catalog {{MSF}} describes an mpeg2ts track. This document extends that
catalog by defining the `mpeg2ts` value for the inherited `packaging` field
and additional fields for track objects that use that value. The catalog track
name, root catalog fields, common track fields, delta update rules, variable
substitution rules, and authorization signaling are inherited unchanged from
MSF unless this document explicitly states otherwise. A parser MUST ignore
fields it does not understand.

## Track Object Fields {#track-fields}

{{track-fields-table}} lists the mpeg2ts-specific fields defined within a
track object. A track whose `packaging` is "mpeg2ts" uses them, and a track
carrying decoded media frames uses `mpeg2tsEsPid`, `mpeg2tsProgramNumber`, and
`mpeg2tsPcrPid` while its `packaging` is "loc" ({{media-frames-carriage}}).

| Field                         | Name                    | Definition |
|:==============================|:========================|:===========|
| Mode                          | mpeg2tsMode               | {{mpeg2ts-mode}} |
| Packet size                   | mpeg2tsPacketSize         | {{mpeg2ts-packet-size}} |
| ES PID                        | mpeg2tsEsPid              | {{mpeg2ts-es-pid}} |
| ES payload                    | mpeg2tsEsPayload          | {{mpeg2ts-es-payload}} |
| Program number                | mpeg2tsProgramNumber      | {{mpeg2ts-program-number}} |
| PCR PID                       | mpeg2tsPcrPid             | {{mpeg2ts-pcr-pid}} |
| Mux rate                      | mpeg2tsMuxRate            | {{mpeg2ts-mux-rate}} |
| SI PIDs                       | mpeg2tsSiPids             | {{mpeg2ts-si-pids}} |
| Random access                 | mpeg2tsRandomAccess       | {{mpeg2ts-random-access}} |
| Timestamp mode                | mpeg2tsTimestampMode      | {{mpeg2ts-timestamp-mode}} |
| SCTE-35 PID                   | mpeg2tsScte35Pid          | {{mpeg2ts-scte35-pid}} |
{: #track-fields-table title="Track object fields defined by this document"}

Use of the MSF `initRef` and `initDataList` fields by mpeg2ts tracks is
described in {{init-data}}.

## Mode {#mpeg2ts-mode}

Required: Yes JSON Type: String Location: Track Object

What the track carries and how the publisher derived it. The value MUST be one
of the six names below, and {{carriage-table}} gives the fields that each one
requires.

| Value | Meaning |
|:==========|:=========|
| unmodified-program | Every packet of a single-program source, unchanged ({{unmodified-program-carriage}}) |
| unmodified-multiplex | Every packet of a multi-program source, unchanged ({{unmodified-multiplex-carriage}}) |
| per-program | One program that the publisher derived from the source ({{per-program-carriage}}) |
| es-packets | The TS source packets of one PID ({{es-level-carriage}}) |
| es-units | The PES packets or the sections of one PID ({{es-units-carriage}}) |
| media-frames | The decoded frames of one elementary stream ({{media-frames-carriage}}) |
{: #mode-table title="Values of mpeg2tsMode"}

A subscriber that does not recognize the value MUST reject the track.

## Packet Size {#mpeg2ts-packet-size}

Required: Conditional JSON Type: Number Location: Track Object

The source-packet size in octets. The value MUST be either 188 or 192. A value
of 188 identifies ordinary MPEG-2 TS packets. A value of 192 identifies M2TS
source packets with a four-octet timestamp prefix followed by a 188-octet TS
packet.

{{carriage-table}} gives the modes that require this field.

## ES PID {#mpeg2ts-es-pid}

Required: Optional JSON Type: Number Location: Track Object

The PID that the single elementary stream or signaling table of this track
held in the source. When present, the track carries only the packets or the
units of that PID, and it never carries null packets. The field appears on an
mpeg2ts track, and on an LOC track carrying decoded media frames
({{media-frames-carriage}}). A track carrying an elementary stream carries
neither PAT nor PMT, and a track whose `role` is "pat" or "pmt" carries that
table alone. The "es-packets", "es-units", and "media-frames" modes require
this field ({{carriage-table}}).

When this field is present, `mpeg2tsSiPids` and `mpeg2tsScte35Pid` MUST be
absent.

The MSF `role` field is a useful companion to `mpeg2tsEsPid`, because a PID
alone does not say what the track carries. For tracks carrying DVB or ATSC SI
tables, publishers SHOULD set `role` to one of the following values: `"nit"`
for the Network Information Table (PID 0x0010), `"sdt"` for the Service
Description Table and Bouquet Association Table (PID 0x0011), `"eit"` for the
Event Information Table (PID 0x0012), and `"tdt"` for the Time and Date Table
and Time Offset Table (PID 0x0014). For tracks carrying SCTE-35 splice
information, publishers SHOULD set `role` to `"scte35"`. For media elementary
streams, publishers SHOULD set `role` to the MSF-defined value for the stream
type, for example `"video"` or `"audio"`.

Two `role` values name the program signaling that {{es-level-carriage}}
requires. For the Program Association Table, publishers SHOULD set `role` to
`"pat"` and `mpeg2tsEsPid` to 0x0000. For the Program Map Table of the carried
program, publishers SHOULD set `role` to `"pmt"` and `mpeg2tsEsPid` to the PID
that the PAT lists for that program.

## ES Payload {#mpeg2ts-es-payload}

Required: Optional JSON Type: String Location: Track Object

The unit that each Object of an "es-units" track carries. The value MUST be
either "pes" or "section". {{es-units-carriage}} defines the mode.

{{payload-units}} defines the Object payload for both values.

This field MUST be absent unless `mpeg2tsEsPid` is present. When it is
present, `mpeg2tsPacketSize` and `mpeg2tsTimestampMode` MUST be absent. A
subscriber that does not recognize the value MUST reject the track, rather
than read its Object payload as source packets.

## Program Number {#mpeg2ts-program-number}

Required: Optional JSON Type: Number Location: Track Object

The MPEG-2 Transport Stream program number carried by this track. When
present, the track SHOULD carry packets from only that program. This field
identifies the selected program in per-program carriage
({{per-program-carriage}}) and the originating program in ES-level carriage
({{es-level-carriage}}). It MUST be absent in the "unmodified-multiplex"
mode.

## PCR PID {#mpeg2ts-pcr-pid}

Required: Optional JSON Type: Number Location: Track Object

The PID carrying the PCR of the program that this track carries. This field is
advisory and does not replace the PCR signaling in the transport stream. It
MUST be absent in the "unmodified-multiplex" mode.

In ES-level carriage, the PCR may travel on a different track. A subscriber
that needs PCR timing for an ES-level track MUST also subscribe to the track
whose `mpeg2tsEsPid` equals the `mpeg2tsPcrPid` declared by that ES-level
track.

## Mux Rate {#mpeg2ts-mux-rate}

Required: Optional JSON Type: Number Location: Track Object

The nominal mux rate of the source transport stream in bits per second,
counted over 188-octet TS packets. The count excludes the four-octet timestamp
prefix of an M2TS source packet.

A publisher SHOULD declare this field when it removes null packets, and on
ES-level tracks, which carry no null packets at all. Where a program is
published as several ES-level tracks, every track of that program SHOULD
declare the same value, which describes the reconstructed program and not any
single track.

The declared rate is a stuffing target rather than a timing source. A
subscriber recovers its clock from the PCR values in the stream, and uses this
rate to decide how much null stuffing to insert.

This field MUST be absent in the "unmodified-multiplex" mode.

## SI PIDs {#mpeg2ts-si-pids}

Required: Optional JSON Type: Array Location: Track Object

An array of the PIDs carrying the SI tables that a per-program track retains.
DVB and ATSC place each table on its own PID, so a publisher retaining more
than one table lists one PID per table. The array does not repeat the PIDs
that the PMT lists.

A publisher SHOULD include this field when it retains SI tables
({{per-program-carriage}}). The field is advisory: a subscriber MAY use it to
learn which tables are present without parsing the packet stream.

This field MUST be absent when `mpeg2tsEsPid` is present, and in the
"unmodified-multiplex" mode. An ES-level track carries one table, which its
`mpeg2tsEsPid` and MSF `role` field identify ({{mpeg2ts-es-pid}}).

## Random Access {#mpeg2ts-random-access}

Required: Optional JSON Type: Boolean Location: Track Object

When true, every MOQT Group starts with a random access point, as defined in
{{group-boundaries}}. When absent or false, this document makes no guarantee
about where in a Group decoding can begin.

## Timestamp Mode {#mpeg2ts-timestamp-mode}

Required: Optional JSON Type: String Location: Track Object

For 192-octet source packets, this field identifies the interpretation of the
four-octet prefix. This field MUST NOT be present when `mpeg2tsPacketSize` is
188.

The value "arrival-time" indicates the Blu-ray Disc Audio/Visual (BDAV)
convention. The four octets are big-endian: the two most significant bits
carry a copy permission indicator, and the remaining 30 bits carry an arrival
time on a 27 MHz clock. That arrival time wraps every 2^30 ticks, or
approximately 39.77 seconds.

The value "opaque" indicates that the publisher carries the prefix without
specified semantics.

## SCTE-35 PID {#mpeg2ts-scte35-pid}

Required: Optional JSON Type: Number Location: Track Object

The PID carrying SCTE-35 splice_info_section() messages for this track. This
field is advisory; SCTE-35 messages are also discoverable via the PMT
conditional access or registration descriptor. When present, a subscriber MAY
use this value to locate splice events without parsing the PMT. Publishers
SHOULD include this field when the track carries SCTE-35 splice signaling.
This field MUST be absent when `mpeg2tsEsPid` is present, and in the
"unmodified-multiplex" mode. When SCTE-35 travels as an ES-level track, the
`mpeg2tsEsPid` and `role` fields of that track identify it.

## Use of MSF Initialization Data {#init-data}

A subscriber obtains the PAT and the PMT in one of four ways: it subscribes to
the PAT and PMT tracks that {{es-level-carriage}} recommends, it reads the
tables from `initDataList` when the track declares `initRef`, it accumulates
packets from the joining point until the publisher repeats the PSI, or it
fetches a past Object that carries them. Only the first way serves a track
that carries no source packets, because the other three read the tables out of
a packet stream.

MSF defines the `initRef` track field and the root `initDataList` field. An
mpeg2ts track MAY use those fields to carry initialization data. The track
sets `initRef` to the `id` of an `initDataList` entry whose `type` MUST be
"inline". On a track that carries source packets, the Base64 {{BASE64}} decoded
value of the entry's `data` field MUST be a sequence of whole source packets
using the packet size that `mpeg2tsPacketSize` declares.

Publishers SHOULD include current PAT and PMT packets in the referenced
initialization data when those tables are not guaranteed to be available at
the first Object of each Group. When PSI changes within a live track, the
publisher SHOULD publish an updated initialization data entry in a new
independent catalog before publishing Objects that rely on the changed PSI.
Subscribers MUST NOT assume that referenced initialization data remains valid
after the MPEG-2 PSI `version_number` changes; updated PSI in media Objects
takes precedence.

A publisher using an unmodified mode ({{unmodified-program-carriage}})
typically omits `initRef`, because it does not inspect the source stream and
the PSI reaches the subscriber unchanged.

On an ES-level track, an `initDataList` entry gives a joining subscriber the
tables at once. The PAT and PMT tracks remain the authoritative source
afterwards.

# Catalog Examples {#catalog-examples}

The following examples are non-normative.

## Live 188-octet Transport Stream {#example-live-ts}

This example shows a live single-program transport stream forwarded unchanged.

~~~ json
{
  "version": "draft-01",
  "generatedAt": 1746104606044,
  "tracks": [
    {
      "name": "program-1-ts",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "unmodified-program",
      "isLive": true,
      "targetLatency": 1000,
      "role": "video",
      "mimeType": "video/mp2t",
      "bitrate": 6000000,
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsPcrPid": 257,
      "mpeg2tsRandomAccess": true
    }
  ]
}
~~~

## Live 192-octet M2TS Source Packets {#example-live-m2ts}

This example shows the same carriage with 192-octet source packets, whose
four-octet prefix `mpeg2tsTimestampMode` interprets.

~~~ json
{
  "version": "draft-01",
  "generatedAt": 1746104606044,
  "tracks": [
    {
      "name": "program-1-mpeg2ts",
      "namespace": "contribution.example.net/feed/a",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "unmodified-program",
      "isLive": true,
      "targetLatency": 500,
      "role": "video",
      "mimeType": "video/mp2t",
      "bitrate": 12000000,
      "mpeg2tsPacketSize": 192,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsTimestampMode": "arrival-time",
      "mpeg2tsRandomAccess": true
    }
  ]
}
~~~

## Video-on-Demand Transport Stream {#example-vod}

This example shows a stored transport stream forwarded unchanged, with
`isLive` false and a track duration.

~~~ json
{
  "version": "draft-01",
  "tracks": [
    {
      "name": "asset-main",
      "namespace": "vod.example.com/assets/1000",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "unmodified-program",
      "isLive": false,
      "trackDuration": 632000,
      "role": "video",
      "mimeType": "video/mp2t",
      "bitrate": 4500000,
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsRandomAccess": true
    }
  ]
}
~~~

## Multi-Program Source - Per-Program Tracks {#example-mpts}

This example shows a catalog for a publisher that receives a 2-program
transport stream and publishes each program as a separate mpeg2ts track. The
two tracks share a namespace but are independent services; `altGroup` is not
used because the programs carry different content.

~~~ json
{
  "version": "draft-01",
  "generatedAt": 1746104606044,
  "tracks": [
    {
      "name": "program-1",
      "namespace": "live.example.com/mux/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "per-program",
      "isLive": true,
      "targetLatency": 1000,
      "role": "video",
      "mimeType": "video/mp2t",
      "bitrate": 6000000,
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsPcrPid": 257,
      "mpeg2tsMuxRate": 6500000,
      "mpeg2tsRandomAccess": true
    },
    {
      "name": "program-2",
      "namespace": "live.example.com/mux/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "per-program",
      "isLive": true,
      "targetLatency": 1000,
      "role": "video",
      "mimeType": "video/mp2t",
      "bitrate": 4000000,
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 2,
      "mpeg2tsPcrPid": 513,
      "mpeg2tsMuxRate": 4500000,
      "mpeg2tsRandomAccess": true
    }
  ]
}
~~~

## Unmodified Multiplex {#example-mpts-transparent}

This example shows a catalog for a publisher that carries a complete
multi-program transport stream without program selection, so no per-program
catalog fields are present.

~~~ json
{
  "version": "draft-01",
  "generatedAt": 1746104606044,
  "tracks": [
    {
      "name": "mux-1",
      "namespace": "live.example.com/mux/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "unmodified-multiplex",
      "isLive": true,
      "targetLatency": 1000,
      "mimeType": "video/mp2t",
      "bitrate": 20000000,
      "mpeg2tsPacketSize": 188
    }
  ]
}
~~~

## Alternate Renditions - Two Bitrate Tracks {#example-abr}

This example shows a catalog for a live channel published at two bitrates as
alternate renditions. Both tracks are in the same `altGroup`; video tracks
MUST align Group boundaries at identical presentation positions. The tracks
use different PID assignments: a subscriber switching between them MUST
re-parse PAT and PMT on the new track before routing packets to a decoder.

~~~ json
{
  "version": "draft-01",
  "generatedAt": 1746104606044,
  "tracks": [
    {
      "name": "video-high",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "unmodified-program",
      "isLive": true,
      "targetLatency": 1000,
      "role": "video",
      "mimeType": "video/mp2t",
      "bitrate": 6000000,
      "altGroup": 1,
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsPcrPid": 257,
      "mpeg2tsRandomAccess": true
    },
    {
      "name": "video-low",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "unmodified-program",
      "isLive": true,
      "targetLatency": 1000,
      "role": "video",
      "mimeType": "video/mp2t",
      "bitrate": 2000000,
      "altGroup": 1,
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsPcrPid": 513,
      "mpeg2tsRandomAccess": true
    }
  ]
}
~~~

## ES-Packets Tracks - One Track per Elementary Stream {#example-es-level}

This example shows a live program published as separate ES-packets tracks: one
video track carrying the PCR, two audio tracks for different languages
(English and Spanish), one Event Information Table track, and the PAT and PMT
tracks that carry the program signaling. The video and audio tracks SHOULD
align their Group boundaries on the same presentation positions.

~~~ json
{
  "version": "draft-01",
  "generatedAt": 1746104606044,
  "tracks": [
    {
      "name": "program-1-video",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "es-packets",
      "isLive": true,
      "targetLatency": 1000,
      "role": "video",
      "mimeType": "video/mp2t",
      "bitrate": 5000000,
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsPcrPid": 257,
      "mpeg2tsMuxRate": 6000000,
      "mpeg2tsEsPid": 257,
      "mpeg2tsRandomAccess": true
    },
    {
      "name": "program-1-audio-en",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "es-packets",
      "isLive": true,
      "targetLatency": 1000,
      "role": "audio",
      "mimeType": "video/mp2t",
      "bitrate": 128000,
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsPcrPid": 257,
      "mpeg2tsMuxRate": 6000000,
      "mpeg2tsEsPid": 258,
      "mpeg2tsRandomAccess": true
    },
    {
      "name": "program-1-audio-es",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "es-packets",
      "isLive": true,
      "targetLatency": 1000,
      "role": "audio",
      "mimeType": "video/mp2t",
      "bitrate": 128000,
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsPcrPid": 257,
      "mpeg2tsMuxRate": 6000000,
      "mpeg2tsEsPid": 259,
      "mpeg2tsRandomAccess": true
    },
    {
      "name": "program-1-eit",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "es-packets",
      "isLive": true,
      "role": "eit",
      "mimeType": "video/mp2t",
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsMuxRate": 6000000,
      "mpeg2tsEsPid": 18
    },
    {
      "name": "program-1-pat",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "es-packets",
      "isLive": true,
      "role": "pat",
      "mimeType": "video/mp2t",
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsEsPid": 0
    },
    {
      "name": "program-1-pmt",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "es-packets",
      "isLive": true,
      "role": "pmt",
      "mimeType": "video/mp2t",
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsEsPid": 256
    }
  ]
}
~~~

A subscriber taking the video track and one audio track also takes the PAT and
PMT tracks, removes the entries of the streams it did not take from the PMT,
and emits the two tables with the packets of the streams it carries.

## No-Packet Tracks - LOC Media, PES, and Sections {#example-no-packet}

This example shows the same program published without TS source packets. The
video track uses LOC packaging, the audio track carries complete PES packets
because the publisher did not decode it, and the Program Map Table travels as
sections on its own track.

~~~ json
{
  "version": "draft-01",
  "generatedAt": 1746104606044,
  "tracks": [
    {
      "name": "program-1-video",
      "namespace": "live.example.com/channel/1",
      "packaging": "loc",
      "mpeg2tsMode": "media-frames",
      "isLive": true,
      "targetLatency": 1000,
      "role": "video",
      "codec": "avc1.640028",
      "mimeType": "video/H264",
      "bitrate": 5000000,
      "initRef": "video-config",
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsPcrPid": 257,
      "mpeg2tsEsPid": 257
    },
    {
      "name": "program-1-audio-en",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "es-units",
      "isLive": true,
      "targetLatency": 1000,
      "role": "audio",
      "mimeType": "video/mp2t",
      "bitrate": 128000,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsPcrPid": 257,
      "mpeg2tsEsPid": 258,
      "mpeg2tsEsPayload": "pes"
    },
    {
      "name": "program-1-pat",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "es-units",
      "isLive": true,
      "role": "pat",
      "mimeType": "video/mp2t",
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsEsPid": 0,
      "mpeg2tsEsPayload": "section"
    },
    {
      "name": "program-1-pmt",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "es-units",
      "isLive": true,
      "role": "pmt",
      "mimeType": "video/mp2t",
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsEsPid": 256,
      "mpeg2tsEsPayload": "section"
    }
  ]
}
~~~

No track declares `mpeg2tsPacketSize`, because no track carries source
packets. The video track carries no `mpeg2tsEsPayload`, because that field
describes an mpeg2ts track. A
subscriber that only plays the video reads the LOC track and ignores the rest
of the catalog.

# Switching and Alternate Renditions {#switching}

A publisher advertises multiple mpeg2ts tracks as alternatives using the MSF
`altGroup` field. Video tracks in the same alternate group MUST place Group
boundaries at identical presentation positions, and other tracks SHOULD align
their Group boundaries to the same positions where possible. A track with
`mpeg2tsMode` set to "unmodified-multiplex" MUST NOT appear in an
`altGroup`.

A subscriber switches between alternate mpeg2ts tracks either at a Group
boundary or at a transport-stream random access point that it can
independently decode. This document does not require continuity counter values
or PID assignments to match across alternate tracks, so a subscriber MUST
treat a switch as a packet-stream discontinuity.

After a switch, a receiver MUST re-initialize its system time clock (STC)
recovery from the first PCR of the new track. It MUST also re-parse the PAT
and PMT of the new track before routing elementary-stream packets to a
decoder.

# Content Protection {#content-protection}

Unmodified carriage preserves any scrambling and conditional access
information present in the MPEG-2 Transport Stream. Per-program carriage
preserves it when the publisher retains the conditional access packets
({{per-program-carriage}}). Neither form of ES-level carriage preserves it,
and neither {{es-units-carriage}} nor {{media-frames-carriage}} can carry a
scrambled stream at all.
Transport-stream scrambling is opaque to MOQT relays and to this
specification.

A publisher MAY apply object-level encryption using a mechanism such as Secure
Objects {{SecureObjects}}, when the catalog signals it. A subscriber then
validates source packets after decrypting the Object payload.

# Security Considerations {#security-considerations}

The security considerations of MOQT {{MOQTransport}}, MSF {{MSF}}, MPEG-2
Transport Stream {{ISO138181}}, and any object encryption scheme apply.

Receivers need to treat transport-stream syntax as untrusted input. Invalid
packet sizes, invalid sync bytes, malformed PSI, inconsistent continuity
counters, excessive table repetition, and timestamp discontinuities can cause
decoder failures or resource exhaustion if not bounded by implementation
policy.

Catalog metadata is also untrusted input. Subscribers MUST validate packet
sizes, payload lengths, Base64 values, PIDs, program numbers, and object
ordering before using the values to allocate memory or configure decoders.

A subscriber cannot check that `mpeg2tsMode` is accurate.
{{object-payload-format}} establishes that a track is well formed, not that
its packets are the ones the publisher received.

Object-level encryption protects MOQT Object payloads but does not hide MOQT
namespace, track name, Group ID, Object ID, object size, or delivery timing
from authorized relays. Applications that require confidentiality for media
payloads SHOULD use an object encryption scheme in addition to transport
security.

# IANA Considerations {#iana-considerations}

This document requests that, once MSF establishes an IANA registry for
packaging values, IANA register the value "mpeg2ts" with this document as the
reference.

--- back

# Acknowledgments

This document follows the repository and draft structure used by the MOQT
Streaming Format work.

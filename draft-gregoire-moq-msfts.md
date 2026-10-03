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
  SecureObjects: I-D.draft-ietf-moq-secure-objects
  MOQMPEGTS: I-D.draft-lcurley-moq-mpegts

--- abstract

This document extends the MOQT Streaming Format (MSF) with the "mpeg2ts"
packaging, which carries the packets of an MPEG-2 Transport Stream over MOQT.
It defines the catalog fields that describe such a track, and the rules that a
publisher and a subscriber follow to carry the packet stream.

--- middle

# Introduction {#introduction}

MPEG-2 Transport Stream MOQT Streaming Format (MSFTS) is an extension of the
MOQT Streaming Format (MSF) {{MSF}} that delivers MPEG-2 Transport Stream (TS)
{{ISO138181}} content over MOQT {{MOQTransport}}. MSFTS keeps the catalog, the
timelines, and the alternate rendition switching of MSF.

An MSFTS track carries whole TS source packets, either 188 or 192 octets
each. It serves a subscriber that feeds equipment expecting a transport
stream, for example an Integrated Receiver Decoder (IRD).

This document describes version 3 of the MSFTS packaging format.

# MSF Extension {#msf-extension}

The requirements and terminology of {{MSF}} apply to this extension unless
this document says otherwise. This document defines the Object payload of an
mpeg2ts track ({{object-payload-format}}) and the catalog fields that describe
the track ({{catalog}}).

This document uses two unrelated version numbers. The catalog `version` field
carries the MSF revision. The MSFTS format version given in {{introduction}}
identifies this packaging specification and never appears in a catalog. A
catalog conforming to this document MUST set `version` as {{MSF}} requires.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

This document uses the following abbreviations from {{ISO138181}}: Elementary
Stream (ES), Packet Identifier (PID), Program Association Table (PAT), Program
Map Table (PMT), Conditional Access Table (CAT), Program Clock Reference
(PCR), Program Specific Information (PSI), Presentation Time Stamp (PTS), and
Decoding Time Stamp (DTS).

This document uses the following terms:

TS packet:
: A 188-octet MPEG-2 Transport Stream packet as defined by {{ISO138181}}.

M2TS source packet:
: A 192-octet packet made of a four-octet prefix and a 188-octet TS packet.
  {{mpeg2ts-timestamp-mode}} defines the prefix.

Source packet:
: Either a TS packet or an M2TS source packet. The catalog signals which of
  the two a track carries.

Subscriber:
: The MOQT endpoint that subscribes to a track and receives its Objects, as
  defined by {{MOQTransport}}. A subscriber operates on MOQT Objects and
  produces the reconstructed packet stream.

Receiver: : The equipment that consumes the reconstructed packet stream, for
example an IRD. A receiver operates on source packets and needs no knowledge
of MOQT.

Random access point:
: A point in the packet stream at which a receiver can begin decoding after
  receiving the PAT, the PMT, and the decoder initialization.

Single-program transport stream:
: A transport stream whose PAT lists exactly one program.

Multi-program transport stream:
: A transport stream whose PAT lists two or more programs.

# Scope

MSFTS carries an MPEG-2 Transport Stream over {{MOQTransport}} as TS packets,
either unchanged or filtered by the publisher. Interoperability requires three
properties:

* An original publisher can map an incoming transport stream into MOQT Objects
  and Groups, describe it in an MSF catalog, and announce it to an MOQT relay.
* An MOQT relay can cache and propagate the tracks without parsing the
  transport stream.
* An end subscriber can parse the catalog, subscribe to the tracks it needs,
  reconstruct the packet stream, and pass it to a receiver.

A subscriber needs to know how the publisher produced each track: the size of
its packets, how the publisher derived the track, which program or elementary
stream it carries, and which track carries the PCR. MSFTS defines the catalog
signaling that carries those decisions from the publisher to the subscriber.

Demultiplexed carriage, where each elementary stream travels without its TS
packets, is out of scope. {{MOQMPEGTS}} addresses it. Error correction is out
of scope as well. Residual loss reaches MSFTS as missing Objects or Groups.

# Media Packaging {#media-packaging}

A track whose Objects carry TS source packets MUST set the MSF `packaging`
field to "mpeg2ts". Such a track carries a single ordered stream of source
packets.

## Object Payload Format {#object-payload-format}

The payload of each MOQT Object is a sequence of whole source packets:

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
packets from received Objects in ascending Group ID and Object ID order. When
a subscriber skips or does not receive an Object, the reconstructed packet
stream has a gap. The Location of the missing Object identifies the gap
exactly. The continuity counters of the source packets after the gap can show
it, but a loss of 16 packets on a PID, or of any multiple of 16, leaves them
unchanged. A subscriber MUST NOT change the continuity counters to hide a gap.
It SHOULD report the Location and the duration of each gap to its operator.

Object boundaries are packaging boundaries. Continuity counters, adaptation
fields, PCR, PTS, DTS, PSI, and other TS syntax remain inside the source
packets.

Object boundaries leave the delivery schedule of the stream unchanged. The PCR
values give the time at which each TS byte is meant to reach the receiver.
Section 2.4.2 of {{ISO138181}} expresses the buffer constraints of a reference
decoder against that schedule. {{ISO138189}} gives the tolerance within which
a delivered stream matches it. {{TR101290}} defines the limits that a Digital
Video Broadcasting (DVB) deployment must meet. {{pcr-timing}} covers how MOQT
delivery relates to the schedule.

## Group Boundaries {#group-boundaries}

A Group SHOULD NOT last longer than 2 seconds. On a live single-program track,
a publisher SHOULD start each MOQT Group at a random access point.

On a track carrying a whole multiplex, a publisher MAY align Group boundaries
to the random access points of the reference program
({{unmodified-multiplex-carriage}}).

When `mpeg2tsRandomAccess` ({{mpeg2ts-random-access}}) is true, the first
Object of every Group contains the first TS packet of a random access point.
The Group SHOULD carry the PAT and the PMT. A publisher SHOULD also provide
the PAT and the PMT in the catalog ({{init-data}}), so that a joining
subscriber can pass them to the receiver before the first Object.

## Joining a Track {#joining}

A subscriber that joins a live track SHOULD start at the beginning of a Group.
When `mpeg2tsRandomAccess` is true, the first Object of that Group contains a
random access point. The subscriber obtains the PAT and the PMT as
{{init-data}} describes.

## Source Handling and Carriage Modes {#carriage-modes}

The required `mpeg2tsMode` field ({{mpeg2ts-mode}}) names what a track carries
and how the publisher derived it. The sections that follow define its four
values.

### Unmodified Program {#unmodified-program-carriage}

The publisher MUST forward the source packets of a single-program transport
stream without modification. The publisher MUST NOT select a program, remap a
PID, rewrite the PAT or the PMT, change a continuity counter, or insert or
remove a null packet. A subscriber then reconstructs the source stream
byte-for-byte. It MUST pass that stream to the receiver unchanged, apart from
the switching signals ({{switching}}), the PAT and PMT copies that it sends
from the catalog at join ({{init-data}}), and the removal of the prefix
({{mpeg2ts-timestamp-mode}}).

A publisher SHOULD verify that its pipeline preserves every source packet
before it declares this mode.

The catalog does not need to describe the program, because the PAT and PMT
reach the subscriber unaltered within one PSI repetition cycle.

### Unmodified Multiplex {#unmodified-multiplex-carriage}

The publisher forwards every source packet of a multi-program transport stream
under the rules of {{unmodified-program-carriage}}. The publisher selects no
program. It MAY name a reference program in `mpeg2tsProgramNumber` and its PCR
PID in `mpeg2tsPcrPid`. A subscriber then paces the multiplex on that PCR, and
`mpeg2tsRandomAccess` refers to the random access points of that program. A
publisher MUST NOT use this mode when the PAT of the source lists one program.

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
* Packets on any PID that the current PMT of the selected program lists,
  including the PCR PID, the PIDs of all elementary streams, and the PIDs that
  any CA_descriptor references.
* Packets carrying the service information (SI) tables that the publisher
  retains, if any.
* Conditional access packets, including the CAT on PID 0x0001.
* Null packets (PID 0x1FFF), which the publisher MAY drop or retain.

A publisher that rewrites a table (the PAT, the PMT, the CAT, or an SI table)
SHOULD emit it at least as often as the source stream did. The publisher sets
the `version_number` of the rewritten table independently of the source table.
It MUST increment the version when the content of the rewritten table changes,
and it MUST NOT increment the version otherwise. When the source PAT stops
listing the carried program, the publisher SHOULD end the track.

A publisher filtering a scrambled transport stream MUST retain the conditional
access packets required for descrambling. Conditional access integration is
application-specific and outside the scope of this document. A CAT carried
from a multi-program source references the entitlement management streams of
every program in the multiplex, so a publisher SHOULD rewrite it to leave only
the entries for the carried program.

The `mpeg2tsProgramNumber` field ({{mpeg2ts-program-number}}) SHOULD be
present on per-program tracks to identify the program carried.

Removing null packets changes the inter-packet byte spacing that
constant-bit-rate receivers use to recover the mux clock. A subscriber wishing
to reconstruct a constant-bit-rate output stream cannot derive the original
rate from the stream alone. The publisher declares that rate in
`mpeg2tsMuxRate` ({{mpeg2ts-mux-rate}}).

A track without SI has no service identity, no event schedule, and no
broadcast time. A publisher targeting broadcast or IRD reception SHOULD retain
the SI tables that the target standard requires. A publisher that retains SI
tables SHOULD list their PIDs in `mpeg2tsSiPids` ({{mpeg2ts-si-pids}}) and
SHOULD rewrite them to leave only the entries for the carried program.

### ES-Packets {#es-level-carriage}

In this mode, the track carries one elementary stream or one signaling table,
on the PID that `mpeg2tsEsPid` ({{mpeg2ts-es-pid}}) identifies. The track MUST
NOT contain null packets.

A publisher using ES-level carriage SHOULD publish the program signaling as
two further tracks, one carrying the PAT and one carrying the PMT of the
program ({{mpeg2ts-es-pid}}). The tables then reach a subscriber as the
publisher produced them, with their descriptors and their stream types intact.
The publisher SHOULD rewrite the PAT to list only the program that it carries.

When `mpeg2tsPcrPid` equals `mpeg2tsEsPid`, the track carries the PCR of the
program. Otherwise another track carries it, and {{pcr-timing}} applies to
that track.

A subscriber that combines ES-level tracks and outputs a TS MUST subscribe to
the PAT track and to the PMT track of the program when the catalog offers
them. It MUST emit both tables before the first packet of any elementary
stream that they describe, and it MUST repeat them at the interval that the
standard governing its output requires, for example {{TR101290}} for a DVB
deployment. When it carries a subset of the elementary streams that the PMT
lists, it MUST remove the entries for the streams it does not carry, correct
the CRC_32 field of the section, and increment its `version_number`. It MUST
subscribe to the track that carries the PCR and take the PCR from it.

The order of the packets within each PID does not give their position in the
multiplex. Only arrival times ({{mpeg2ts-timestamp-mode}}) stamped on one
clock across all the tracks of a program give that position.

A subscriber that finds no PAT track and no PMT track cannot produce a
conformant PMT, because the catalog carries no stream type for an elementary
stream. Such a subscriber MUST NOT present its output as a conformant
transport stream.

An ES-level track carries no CAT, so it carries no conditional access
association between a scrambled elementary stream and the streams that key it.
A publisher also cannot identify random access points in a payload it cannot
decrypt, so it cannot set `mpeg2tsRandomAccess` to true. A publisher carrying
a scrambled source SHOULD use unmodified or per-program carriage.

## PCR and Timing {#pcr-timing}

The PCR travels in the adaptation fields of the TS packets ({{ISO138181}}).
MOQT Object and Group boundaries do not affect its continuity within a track.

A publisher MUST NOT introduce a PCR discontinuity within a single MOQT Group.
A publisher that introduces a PCR discontinuity between consecutive MOQT
Groups MUST signal it by setting the discontinuity_indicator bit
({{ISO138181}}, Section 2.4.3.5) in the adaptation field of the first TS
packet carrying PCR in the new Group. The PCR base wraps every 2^33 ticks of
its 90 kHz clock, about 26.5 hours. A wrap is not a discontinuity. A publisher
MUST NOT signal it as one.

## Egress Timing {#egress-timing}

A subscriber cannot recover the source mux clock from the arrival of packets.
MOQT delivers whole Objects, which a relay can serve as fast as the link
allows. The timing of arrivals at the subscriber therefore carries no
information about the source schedule. The reconstructed stream meets its
schedule only if the subscriber hands each source packet to the receiver at
the time that the PCR values give.

A subscriber whose receiver recovers its clock from packet arrival MUST
deliver the source packets on a schedule consistent with the PCR values they
carry. In the unmodified modes, that schedule is the input schedule of the
T-STD ({{ISO138181}}, Section 2.4.2), so a subscriber that meets this
requirement keeps the T-STD conformance of the source. In the other modes,
conformance also depends on the changes that the publisher made. A subscriber
that feeds such a receiver SHOULD meet the PCR repetition and accuracy limits
of the standard governing the receiver, given by {{TR101290}} for a DVB
deployment. Where the receiver expects a constant bit rate and the track is in
neither unmodified mode, the subscriber SHOULD use `mpeg2tsMuxRate`
({{mpeg2ts-mux-rate}}) as the stuffing target.

Neither a stuffing target nor arrival times reproduce the source schedule. A
stuffing target gives a nominal rate, from which the source clock can deviate
by up to 30 ppm ({{ISO138181}}). Arrival times ({{mpeg2ts-timestamp-mode}})
give the spacing of the packets on the clock that stamped them. They carry no
absolute time. They do not say where the stamping took place. Reproducing the
source schedule at a constant latency requires timing information that this
document does not define.

## Splice Signaling {#splice-signaling}

SCTE-35 {{SCTE35}} splice information travels in band, as
splice_info_section() messages on a PID of the program. The `mpeg2tsScte35Pid`
field ({{mpeg2ts-scte35-pid}}) can declare that PID. This document does not
specify SCTE-35 processing.

A publisher MAY also publish the same splice events out of band, on an MSF
Event Timeline track. {{SCTE35Timeline}} defines the event type identifiers
and the payload format for that track. A subscriber can then read splice
events without parsing the packet stream.

# Catalog {#catalog}

This document extends the MSF catalog {{MSF}} with the "mpeg2ts" value of the
`packaging` field and with the track fields of {{track-fields}}. The rest of
the catalog follows MSF unchanged, including the root fields, the common track
fields, delta updates, and authorization. A parser MUST ignore fields it does
not understand.

Several track fields copy values from the PSI of the source:
`mpeg2tsProgramNumber`, `mpeg2tsPcrPid`, `mpeg2tsEsPid`, `mpeg2tsSiPids`, and
`mpeg2tsScte35Pid`. MSF does not allow the fields of a declared track to
change ({{MSF}}, Section 5.3). For the advisory fields, the PSI in the packets
takes precedence, and the publisher MAY leave the catalog unchanged when the
PSI changes. When the PSI changes `mpeg2tsEsPid` or `mpeg2tsProgramNumber`,
the publisher MUST publish a new track that carries the new value and remove
the old track.

## Track Object Fields {#track-fields}

{{track-fields-table}} lists the track object fields that this document
defines for an mpeg2ts track.

| Field                         | Name                    | Definition |
|:==============================|:========================|:===========|
| Mode                          | mpeg2tsMode               | {{mpeg2ts-mode}} |
| Packet size                   | mpeg2tsPacketSize         | {{mpeg2ts-packet-size}} |
| ES PID                        | mpeg2tsEsPid              | {{mpeg2ts-es-pid}} |
| Program number                | mpeg2tsProgramNumber      | {{mpeg2ts-program-number}} |
| PCR PID                       | mpeg2tsPcrPid             | {{mpeg2ts-pcr-pid}} |
| Mux rate                      | mpeg2tsMuxRate            | {{mpeg2ts-mux-rate}} |
| SI PIDs                       | mpeg2tsSiPids             | {{mpeg2ts-si-pids}} |
| Random access                 | mpeg2tsRandomAccess       | {{mpeg2ts-random-access}} |
| Timestamp mode                | mpeg2tsTimestampMode      | {{mpeg2ts-timestamp-mode}} |
| SCTE-35 PID                   | mpeg2tsScte35Pid          | {{mpeg2ts-scte35-pid}} |
{: #track-fields-table title="Track object fields defined by this document"}

{{init-data}} describes how an mpeg2ts track uses the MSF `initRef` and
`initDataList` fields.

## Mode {#mpeg2ts-mode}

Required: Yes JSON Type: String Location: Track Object

What the track carries and how the publisher derived it. The value MUST be one
of the four names in {{mode-table}}.

| Value | Meaning |
|:==========|:=========|
| unmodified-program | Every packet of a single-program source, unchanged ({{unmodified-program-carriage}}) |
| unmodified-multiplex | Every packet of a multi-program source, unchanged ({{unmodified-multiplex-carriage}}) |
| per-program | One program that the publisher derived from the source ({{per-program-carriage}}) |
| es-packets | The TS source packets of one PID ({{es-level-carriage}}) |
{: #mode-table title="Values of mpeg2tsMode"}

A subscriber that does not recognize the value MUST reject the track. A
subscriber that outputs a transport stream MUST support the
"unmodified-program" mode with 188-octet source packets.

## Packet Size {#mpeg2ts-packet-size}

Required: Yes JSON Type: Number Location: Track Object

The source-packet size in octets. The value MUST be either 188 or 192. A value
of 188 identifies ordinary MPEG-2 TS packets. A value of 192 identifies M2TS
source packets, whose four-octet prefix {{mpeg2ts-timestamp-mode}} describes.

## ES PID {#mpeg2ts-es-pid}

Required: Conditional JSON Type: Number Location: Track Object

The PID that the elementary stream or signaling table of this track held in
the source. The track carries only the packets of that PID. A track that
carries an elementary stream carries neither the PAT nor the PMT. A track
whose `role` is "pat" or "pmt" carries that table alone. This field MUST be
present in the "es-packets" mode and MUST be absent in the other modes. A
subscriber MUST reject a track that breaks this rule.

A PID alone does not say what a track carries. A publisher SHOULD set the MSF
`role` field of an ES-level track as {{role-table}} gives.

| role | Content | mpeg2tsEsPid |
|:=====|:========|:=============|
| "pat" | PAT | 0x0000 |
| "pmt" | PMT of the carried program | The PID that the PAT lists |
| "nit" | Network Information Table | 0x0010 |
| "sdt" | Service Description Table and Bouquet Association Table | 0x0011 |
| "eit" | Event Information Table | 0x0012 |
| "tdt" | Time and Date Table and Time Offset Table | 0x0014 |
| "scte35" | SCTE-35 splice information | The PID that the PMT lists |
| MSF value, for example "video" or "audio" | Media elementary stream | The PID that the PMT lists |
{: #role-table title="Values of role on an ES-level track"}

## Program Number {#mpeg2ts-program-number}

Required: Optional JSON Type: Number Location: Track Object

The MPEG-2 Transport Stream program number carried by this track. This field
identifies the selected program in per-program carriage
({{per-program-carriage}}) and the originating program in ES-level carriage
({{es-level-carriage}}). Outside the "unmodified-multiplex" mode, the track
SHOULD carry packets from only that program. In the "unmodified-multiplex"
mode, it names the reference program ({{unmodified-multiplex-carriage}}).

## PCR PID {#mpeg2ts-pcr-pid}

Required: Optional JSON Type: Number Location: Track Object

The PID carrying the PCR of the program that this track carries. This field is
advisory and does not replace the PCR signaling in the transport stream. In
the "unmodified-multiplex" mode, it names the PCR PID of the reference program
({{unmodified-multiplex-carriage}}).

## Mux Rate {#mpeg2ts-mux-rate}

Required: Optional JSON Type: Number Location: Track Object

The constant rate, in bits per second, to which a subscriber pads the
reconstructed packet stream. The rate counts 188-octet TS packets and excludes
the four-octet prefix of an M2TS source packet. For a track derived from a
single-program transport stream, the value is the nominal mux rate of the
source. For a program derived from a multi-program transport stream, the
publisher chooses the value, because the program has no rate of its own in the
multiplex. That value SHOULD NOT be lower than the peak rate of the program.

A publisher SHOULD declare this field when it removes null packets, and on
ES-level tracks, which carry no null packets at all. Where a program is
published as several ES-level tracks, every track of that program SHOULD
declare the same value, which describes the reconstructed program.

The declared rate is a stuffing target ({{egress-timing}}). A subscriber
recovers its clock from the PCR values and uses the rate to decide how much
null stuffing to insert.

This field MUST be absent in the "unmodified-multiplex" mode.

## SI PIDs {#mpeg2ts-si-pids}

Required: Optional JSON Type: Array Location: Track Object

An array of the PIDs that carry the SI tables that a per-program track retains
({{per-program-carriage}}), each PID listed once. The array does not repeat
the PIDs that the PMT lists.

The field is advisory. A subscriber MAY use it to learn which tables are
present without parsing the packet stream.

This field MUST be absent when `mpeg2tsEsPid` is present, and in the
"unmodified-multiplex" mode. An ES-level track carries one table, which its
`mpeg2tsEsPid` and MSF `role` field identify ({{mpeg2ts-es-pid}}).

## Random Access {#mpeg2ts-random-access}

Required: Optional JSON Type: Boolean Location: Track Object

When true, the first Object of every MOQT Group contains a random access point
({{group-boundaries}}). When absent or false, this document makes no guarantee
about where in a Group decoding can begin. In the "unmodified-multiplex" mode,
this field refers to the reference program, and it MUST be absent when the
catalog names none.

## Timestamp Mode {#mpeg2ts-timestamp-mode}

Required: Optional JSON Type: String Location: Track Object

This field gives the meaning of the four-octet prefix of a 192-octet source
packet. This field MUST NOT be present when `mpeg2tsPacketSize` is 188. When a
192-octet track omits this field, a subscriber treats the prefix as "opaque".

The value "arrival-time" indicates the Blu-ray Disc Audio/Visual (BDAV)
convention. The four octets are big-endian: the two most significant bits
carry a copy permission indicator, and the remaining 30 bits carry an arrival
time on a 27 MHz clock. That arrival time wraps every 2^30 ticks, or
approximately 39.77 seconds.

The value "opaque" indicates that the publisher carries the prefix without
specified semantics.

A subscriber that feeds a receiver expecting 188-octet TS packets MUST remove
the prefix of each source packet.

## SCTE-35 PID {#mpeg2ts-scte35-pid}

Required: Optional JSON Type: Number Location: Track Object

The PID carrying SCTE-35 splice_info_section() messages for this track. This
field is advisory. SCTE-35 messages are also discoverable from the PMT. When
present, a subscriber MAY use this value to locate splice events without
parsing the PMT. Publishers SHOULD include this field when the track carries
SCTE-35 splice signaling. This field MUST be absent when `mpeg2tsEsPid` is
present, and in the "unmodified-multiplex" mode. When SCTE-35 travels as an
ES-level track, the `mpeg2tsEsPid` and `role` fields of that track identify
it.

## Use of MSF Initialization Data {#init-data}

A subscriber obtains the PAT and the PMT in one of four ways: it subscribes to
the PAT and PMT tracks that {{es-level-carriage}} recommends, it reads the
tables from `initDataList` when the track declares `initRef`, it accumulates
packets from the joining point until the publisher repeats the PSI, or it
fetches a past Object that carries them.

MSF defines the `initRef` track field and the root `initDataList` field. An
mpeg2ts track MAY use those fields to carry initialization data. The track
sets `initRef` to the `id` of an `initDataList` entry whose `type` MUST be
"inline". The Base64 {{BASE64}} decoded value of the entry's `data` field MUST
be a sequence of whole source packets using the packet size that
`mpeg2tsPacketSize` declares.

Publishers SHOULD include current PAT and PMT packets in the referenced
initialization data when those tables are not guaranteed to be available at
the first Object of each Group. When PSI changes within a live track, the
publisher SHOULD publish an updated initialization data entry in a new
independent catalog before publishing Objects that rely on the changed PSI.
Subscribers MUST NOT assume that referenced initialization data remains valid
after the MPEG-2 PSI `version_number` changes. Updated PSI in the Objects
takes precedence.

A publisher SHOULD provide `initRef` when `mpeg2tsRandomAccess` is true
({{group-boundaries}}). A subscriber that passes the PAT and the PMT from the
catalog to the receiver SHOULD set the continuity counter of each of these
packets to one less than the continuity counter of the next packet on the same
PID. The receiver then counts no continuity error at the join.

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

## Multi-Program Source - Per-Program Tracks {#example-mpts}

This example shows a catalog for a publisher that receives a two-program
transport stream and publishes each program as a per-program track. The two
tracks share a namespace.

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

## Per-Program Track with Initialization Data {#example-init-data}

This example shows a per-program track whose PAT and PMT also travel in the
catalog, so a joining subscriber has the tables before the first Object
arrives ({{init-data}}). The `data` value holds one PAT packet and one PMT
packet, 376 octets in total. The example shortens its Base64 encoding.

~~~ json
{
  "version": "draft-01",
  "generatedAt": 1746104606044,
  "tracks": [
    {
      "name": "program-1",
      "namespace": "live.example.com/channel/1",
      "packaging": "mpeg2ts",
      "mpeg2tsMode": "per-program",
      "isLive": true,
      "targetLatency": 1000,
      "role": "video",
      "mimeType": "video/mp2t",
      "bitrate": 6000000,
      "initRef": "program-1-psi",
      "mpeg2tsPacketSize": 188,
      "mpeg2tsProgramNumber": 1,
      "mpeg2tsPcrPid": 257
    }
  ],
  "initDataList": [
    {
      "id": "program-1-psi",
      "type": "inline",
      "data": "R0AAEAAAsA0AAcEAAAAB4QDo+V59////..."
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
alternate renditions. Each rendition comes from its own single-program encoder
output, which the publisher forwards unchanged. When the renditions arrive as
programs of one multi-program transport stream, each track uses the
"per-program" mode and carries a common program number ({{switching}}). Both
tracks are in the same `altGroup`, so they align their Group boundaries. The
two tracks carry the PCR on different PIDs (257 and 513), so their PMTs
differ. A subscriber that switches between them follows {{switching}}.

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
tracks that carry the program signaling.

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
      "mpeg2tsMuxRate": 6000000,
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
      "mpeg2tsMuxRate": 6000000,
      "mpeg2tsEsPid": 256
    }
  ]
}
~~~

A subscriber taking the video track and one audio track also takes the PAT and
PMT tracks, removes the entries of the streams it did not take from the PMT,
and emits the two tables with the packets of the streams it carries.

# Switching and Alternate Renditions {#switching}

A publisher advertises multiple mpeg2ts tracks as alternatives using the MSF
`altGroup` field. Video tracks in the same alternate group MUST place Group
boundaries at identical presentation positions. Other tracks SHOULD align
their Group boundaries to the same positions where possible. A track with
`mpeg2tsMode` set to "unmodified-multiplex" MUST NOT appear in an `altGroup`.
Tracks in the same alternate group SHOULD carry the same program number,
because a receiver selects a service by its `program_number`. A per-program
publisher can rewrite the PAT, the PMT, and the SI tables to meet this rule.

A subscriber switches between alternate mpeg2ts tracks at a Group boundary or
at a random access point that it can decode independently. Alternate tracks do
not have to share continuity counter values, PID assignments, or a timebase,
so a switch is a discontinuity in the packet stream. A subscriber that outputs
the packet stream to a receiver MUST make the discontinuity visible to it. The
subscriber MUST set the discontinuity_indicator ({{ISO138181}}, Section
2.4.3.5) in the first packet that carries the PCR after the switch, and it
SHOULD set it in the first packet of each other PID. It MUST also emit the PAT
and the PMT of the new track with a `version_number` that differs from the one
it last emitted, so that the receiver reads the new tables.

# Content Protection {#content-protection}

Unmodified carriage preserves any scrambling and conditional access
information present in the MPEG-2 Transport Stream. Per-program carriage
preserves it when the publisher retains the conditional access packets
({{per-program-carriage}}). ES-level carriage does not preserve it
({{es-level-carriage}}). TS-level scrambling is opaque to MOQT relays and to
this specification.

A publisher MAY encrypt the Object payloads, for example with Secure
Objects {{SecureObjects}}. A subscriber validates the source packets after it
decrypts the payload.

# Security Considerations {#security-considerations}

The security considerations of MOQT {{MOQTransport}}, MSF {{MSF}}, MPEG-2
Transport Stream {{ISO138181}}, and any object encryption scheme apply.

Subscribers and receivers treat TS syntax as untrusted input. Invalid packet
sizes, invalid sync bytes, malformed PSI, inconsistent continuity counters,
excessive table repetition, and timestamp discontinuities can cause decoder
failures or resource exhaustion unless the implementation bounds them.

Catalog metadata is also untrusted input. A subscriber MUST check that each
catalog value is in its valid range before it uses the value, including the
packet size, the PIDs, the program numbers, the mux rate, and the Base64
initialization data.

A subscriber cannot check that `mpeg2tsMode` is accurate. The rules of
{{object-payload-format}} let it check that a track is well formed, but not
that its packets are the ones that the publisher received.

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

The authors thank Thomas Drapier, Luke Curley, and Tilson Joji for their
reviews and discussions.

# CIDv1.eth - On-Chain CIDv1 Encoder

A Solidity library for on-chain CIDv1 encoding, primarily using raw format for efficient on-chain content addressing. This library provides comprehensive multiformat utilities for encoding various data formats into Content Identifiers (CIDs) that can be used in smart contracts for IPFS/IPLD content referencing.

## Quick Start

```solidity
import {RAW} from "./src/multiformats/multicodec/raw-bin.sol";

// Basic CIDv1 encoding with raw format
bytes memory data = "Hello World";
bytes memory cid = RAW.raw(data);
// Returns: 0x0155000b48656c6c6f20576f726c64

// With SHA-256 hash for content verification
bytes memory cidSha256 = RAW.rawSha256(data);
// Returns: 0x01551220a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e

// With Keccak-256 hash (Ethereum compatible)
bytes memory cidKeccak256 = RAW.rawKeccak256(data);
// Returns: 0x01551b20592fa743889fc7f92ac2a37bb1f5ba1daf2a5c84741ca0e0061d243a2e6707ba
```

## Usage Examples & Specifications

### RAW Binary Encoding (0x55)
**Specification**: [IPLD RAW](https://ipld.io/specs/codecs/raw/)  
**Features**: Direct binary data encoding, identity hash support, minimal overhead  
**Functions**: `raw()`, `encode()`

```solidity
import {RAW} from "./src/multiformats/multicodec/raw-bin.sol";

// Basic raw encoding with identity hash
bytes memory data = "Hello World";
bytes memory cid = RAW.raw(data);
// Returns: 0x0155000b48656c6c6f20576f726c64

// With SHA-256 hash for content verification
bytes memory cidSha256 = RAW.rawSha256(data);
// Returns: 0x01551220a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e

// With Keccak-256 hash (Ethereum compatible)
bytes memory cidKeccak256 = RAW.rawKeccak256(data);
// Returns: 0x01551b20592fa743889fc7f92ac2a37bb1f5ba1daf2a5c84741ca0e0061d243a2e6707ba

```

### JSON-UTF8 Encoding (0x01800400) - Recommended for JSON
**Specification**: [IPLD JSON-UTF8](https://ipld.io/specs/codecs/json-utf8/)  
**Features**: Binary JSON encoding, UTF-8 byte representation, gas-efficient JSON handling  
**Functions**: `encode()`, `json()`, `kvJson()`

```solidity
import {JSON_UTF8} from "./src/multiformats/multicodec/json-utf8.sol";

// Encode JSON with identity hash
bytes memory jsonData = bytes('{"key":"value"}');
bytes memory cid = JSON_UTF8.encode(jsonData);
// Returns: 0x01800400117b226b6579223a2276616c7565227d

// Encode JSON with SHA-256 hash
bytes memory cidSha256 = JSON_UTF8.encodeSha256(jsonData);
// Returns: 0x0180041220[32-byte-hash]

// Encode JSON with Keccak-256 hash
bytes memory cidKeccak256 = JSON_UTF8.encodeKeccak256(jsonData);
// Returns: 0x0180041b20[32-byte-hash]

```

### DAG-CBOR Directory Structure (0x71)
**Specification**: [IPLD DAG-CBOR](https://ipld.io/specs/codecs/dag-cbor/)  
**Features**: CBOR encoding for complex data structures, map and array support, CID embedding with proper tag encoding  
**Functions**: `dagcbor()`, `map()`, `array()`, `encode()`

```solidity
import {DAG_CBOR} from "./src/multiformats/multicodec/dag-cbor.sol";
import {RAW} from "./src/multiformats/multicodec/raw-bin.sol";
import {JSON_UTF8} from "./src/multiformats/multicodec/json-utf8.sol";

// Create individual file CIDs
bytes memory file1 = RAW.raw("File 1 content");
bytes memory file2 = JSON_UTF8.encode('{"metadata":"value"}');

// Create directory with multiple files
DAG_CBOR.KV[] memory entries = new DAG_CBOR.KV[](2);
entries[0] = DAG_CBOR.KV("file1.txt", file1);
entries[1] = DAG_CBOR.KV("config.json", file2);

bytes memory directory = DAG_CBOR.map(entries);
bytes memory cid = DAG_CBOR.encode(directory);
// Returns: 0x017100[directory-cbor-data]

// Complex directory with multiple file types
DAG_CBOR.KV[] memory complexEntries = new DAG_CBOR.KV[](4);
complexEntries[0] = DAG_CBOR.KV("sha256.txt", RAW.rawSha256("Hello World"));
complexEntries[1] = DAG_CBOR.KV("identity.txt", RAW.raw("Hello World"));
complexEntries[2] = DAG_CBOR.KV("vitalik", hex"0170000f6170702e756e69737761702e6f7267"); // external ipfs hash
complexEntries[3] = DAG_CBOR.KV("config.json", JSON_UTF8.encode('{"test":"data"}'));

bytes memory complexDir = DAG_CBOR.map(complexEntries);
bytes memory complexCid = DAG_CBOR.encode(complexDir);
// Returns: 0x01710078a36a7368613235362e747874d82a58250001551220a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e6c6964656e746974792e747874d82a50000155000b48656c6c6f20576f726c646b766974616c696b2e657468d82a54000170000f6170702e756e69737761702e6f7267
```

### DAG-PB Directory Encoding (0x70)
**Specification**: [IPLD DAG-PB](https://ipld.io/specs/codecs/dag-pb/)  
**Features**: Protocol Buffer wire format, UnixFS compatibility, link and node encoding  
**Functions**: `encodePBLink()`, `encodePBNode()`, `directory()`, `link()`

```solidity
import {DAG_PB} from "./src/multiformats/multicodec/dag-pb.sol";
import {RAW} from "./src/multiformats/multicodec/raw-bin.sol";

// Create file content
string memory content = "Hello IPFS";
bytes memory fileCID = RAW.raw(bytes(content));

// Create link to file
bytes memory link = DAG_PB.link(fileCID, "hello.txt", bytes(content).length);

// Create directory with links
bytes[] memory links = new bytes[](1);
links[0] = link;
bytes memory directory = DAG_PB.directory(links);

// Create final CID
bytes memory dirCID = abi.encodePacked(
    bytes1(0x01), // CIDv1
    bytes1(0x70), // dag-pb codec
    bytes1(0x00), // identity multihash
    directory.length.varint(),
    directory
);
// Returns: 0x01700023121d0a0e0155000a48656c6c6f2049504653120968656c6c6f2e747874180a0a020801

// Directory with multiple links
bytes memory link1 = DAG_PB.link(RAW.raw("Hello"), "hello.txt", 5);
bytes memory link2 = DAG_PB.link(RAW.raw("World"), "world.txt", 5);
bytes[] memory multiLinks = new bytes[](2);
multiLinks[0] = link1;
multiLinks[1] = link2;
bytes memory multiDir = DAG_PB.directory(multiLinks);
// Returns: 0x122f0a221220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad120968656c6c6f2e747874122f0a221220b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde91209776f726c642e74787401
```

### DAG-JSON Encoding (0x0129) - String-based, Less Efficient
**Specification**: [IPLD DAG-JSON](https://ipld.io/specs/codecs/dag-json/)  
**Features**: JSON string encoding, link format support, map structure encoding  
**Note**: String-based, less efficient than JSON-UTF8  
**Functions**: `encode()`, `link()`, `mapDagJson()`

```solidity
import {DAG_JSON} from "./src/multiformats/multicodec/dag-json.sol";

// Encode JSON data in DAG-JSON format
bytes memory jsonData = bytes('{"Hello":"World"}');
bytes memory dagJson = DAG_JSON.encode(jsonData);
// Returns: 0x01a902117b2248656c6c6f223a22576f726c64227d

// Create DAG-JSON link
string memory key = "test";
bytes memory targetCID = hex"0170000a48656c6c6f20576f726c64";
bytes memory link = DAG_JSON.link(key, targetCID);
// Returns: {"test":{"/":"f0170000a48656c6c6f20576f726c64"}}

// Create map with multiple links
JSON_UTF8.KeyValue[] memory kv = new JSON_UTF8.KeyValue[](2);
kv[0] = JSON_UTF8.KeyValue("file1", hex"0170000a48656c6c6f20576f726c64");
kv[1] = JSON_UTF8.KeyValue("file2", hex"0170000a476f6f64627965");
bytes memory mapResult = DAG_JSON.mapDagJson(kv);
// Returns: {"file1":{"/":"f0170000a48656c6c6f20576f726c64"},"file2":{"/":"f0170000a476f6f64627965"}}

// Empty map
JSON_UTF8.KeyValue[] memory emptyKv = new JSON_UTF8.KeyValue[](0);
bytes memory emptyMap = DAG_JSON.mapDagJson(emptyKv);
// Returns: {}

// Unicode key-value
JSON_UTF8.KeyValue memory unicodeKv = JSON_UTF8.KeyValue("测试", hex"0170000a48656c6c6f20576f726c64");
string memory unicodeResult = DAG_JSON.keyValueToDagJson(unicodeKv);
// Returns: {"测试":{"/":"f0170000a48656c6c6f20576f726c64"}}
```

### UnixFS File System
**Specification**: [UnixFS](https://docs.ipfs.io/concepts/file-systems/#unixfs)  
**Features**: File and directory node encoding, metadata support, symlink handling, block size management  
**Types**: Raw, Directory, File, Metadata, Symlink

```solidity
import {UnixFS} from "./src/multiformats/multicodec/unix-fs.sol";

// Create raw file node
bytes memory data = "Hello IPFS";
bytes memory rawNode = UnixFS.raw(data);
// Returns: 0x0800120a48656c6c6f2049504653

// Create file node with metadata
bytes memory fileData = "This is a simple file content";
bytes memory fileNode = UnixFS.file(fileData, 29);
// Returns: 0x0802121d5468697320697320612073696d706c652066696c6520636f6e74656e74181d201d

// Create metadata node
bytes memory metadataContent = "metadata content";
bytes memory metadataNode = UnixFS.metadata(metadataContent);
// Returns: 0x080312106d6574616461746120636f6e74656e74

// Create symlink
bytes memory symlinkTarget = "../data/hello.txt";
bytes memory symlinkNode = UnixFS.symlink(symlinkTarget);
// Returns: 0x080412112e2e2f646174612f68656c6c6f2e747874

// Create directory node
string[] memory names = new string[](2);
names[0] = "hello.txt";
names[1] = "world.txt";
bytes[] memory hashes = new bytes[](2);
hashes[0] = hex"1220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
hashes[1] = hex"1220b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
bytes memory dirNode = UnixFS.directory(names, hashes);
// Returns: 0x122f0a221220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad120968656c6c6f2e747874122f0a221220b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde91209776f726c642e74787401
```

### Multihash Implementations

#### SHA-256 (0x12)
**Specification**: [Multihash SHA-256](https://multiformats.io/multihash/)  
**Hash Function**: SHA-256  
**Length**: 32 bytes  
**Prefix**: `0x1220`

#### Keccak-256 (0x1b)
**Specification**: [Multihash Keccak-256](https://multiformats.io/multihash/)  
**Hash Function**: Keccak-256 (Ethereum compatible)  
**Length**: 32 bytes  
**Prefix**: `0x1b20`

#### Identity (0x00)
**Specification**: [Multihash Identity](https://multiformats.io/multihash/)  
**Hash Function**: Identity (raw data)  
**Length**: Variable  
**Prefix**: `0x00` + length

### Utility Libraries

#### Varint Encoding
**Specification**: [Multiformats Varint](https://multiformats.io/unsigned-varint/)  
**Features**: Variable-length integer encoding, continuation bit support, uint256 compatibility  
**Functions**: `varint()`, `encode()`

## Development

### Build
```shell
forge build
```

### Test
```shell
forge test
```

### Coverage
```shell
forge coverage
```

## Test Coverage

| File                                        | % Lines          | % Statements     | % Branches     | % Funcs         |
|---------------------------------------------|------------------|------------------|----------------|-----------------|
| src/cidv1.sol                               | 0.00% (0/9)      | 0.00% (0/11)     | 0.00% (0/4)    | 0.00% (0/2)     |
| src/multiformats/multicodec/dag-cbor.sol    | 100.00% (41/41)  | 100.00% (50/50)  | 100.00% (6/6)  | 100.00% (8/8)   |
| src/multiformats/multicodec/dag-json.sol    | 100.00% (27/27)  | 100.00% (27/27)  | 100.00% (3/3)  | 100.00% (5/5)   |
| src/multiformats/multicodec/dag-pb.sol      | 100.00% (28/28)  | 100.00% (31/31)  | 100.00% (1/1)  | 100.00% (10/10) |
| src/multiformats/multicodec/json-utf8.sol   | 100.00% (12/12)  | 100.00% (9/9)    | 100.00% (0/0)  | 100.00% (6/6)   |
| src/multiformats/multicodec/raw-bin.sol     | 100.00% (6/6)    | 100.00% (3/3)    | 100.00% (0/0)  | 100.00% (3/3)   |
| src/multiformats/multicodec/unix-fs.sol     | 100.00% (34/34)  | 100.00% (46/46)  | 100.00% (4/4)  | 100.00% (6/6)   |
| src/multiformats/multihash/identity-raw.sol | 100.00% (2/2)    | 100.00% (1/1)    | 100.00% (0/0)  | 100.00% (1/1)   |
| src/multiformats/multihash/keccak-256.sol   | 100.00% (4/4)    | 100.00% (4/4)    | 100.00% (0/0)  | 100.00% (2/2)   |
| src/multiformats/multihash/sha-256.sol      | 100.00% (4/4)    | 100.00% (4/4)    | 100.00% (0/0)  | 100.00% (2/2)   |
| src/multiformats/varint.sol                 | 100.00% (10/10)  | 100.00% (13/13)  | 100.00% (4/4)  | 100.00% (1/1)   |
| **Total**                                   | **94.82% (183/193)** | **94.39% (202/214)** | **82.61% (19/23)** | **95.92% (47/49)** |

## License
WTFPL.ETH

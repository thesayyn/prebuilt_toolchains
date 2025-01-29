"Sysroot extensions"

MACOS_VERSIONS = {
    "14.4": struct(
        url = "https://swcdn.apple.com/content/downloads/14/48/052-59890-A_I0F5YGAY0Y/p9n40hio7892gou31o1v031ng6fnm9sb3c/CLTools_macOSNMOS_SDK.pkg",
        sha256 = "6f35bd96401f2a07a8ab8f21321f2706a51d2309da7406fb81fbefd16af3c9d0",
        ranges = [(1501203, "5e98decc335ce99cdd00cf1d201b22a5300d1ba2a8e8594980b92bcb432f174d"), (3287435, "889301defedcb64be2827e2d6c93b38be970afe9576e79667d0a303bde9cd71e"), (5100967, "845cefda638d13df6f0aa37be573129975a54e27402bdb5ed8ab83a560f85009"), (5724759, "58b7a1ba1f7c46484c623dc6da9ab924139c89ed3542600d3dd3b0cb695b0f3b"), (6796531, "77fad940028e9f0491835059712d26edf40093cc62119d88c5d1f0addd64ce22"), (8754175, "268a4b7f27c263fb35a9b5af7d00b8b7b85a73d67a1af245dd8ae71951679693"), (10275935, "6a90aa372660db3312963ebe829dc50bed3f43a564763a8a05963380fa40aac4"), (12042791, "7c02717bd328bdb86414feea30e9692e4cbdbcc79ad2d07975f4a68d3b83832f"), (13799539, "5745c960d72b1e9a2987a375e9a05440ae70666071c3b74f10226017f895ea3e"), (15457683, "f8f3734467cbc4c9c10591812efb811dc89656e16076ac12e6af710fef7cdeca"), (17282923, "6e9c1da4329efc796005c53432aaf80efd10fb9a481c56e642ba92f3f9597751"), (18825523, "49a01253e7739120a3ff415e87d300e26a7a408e48c005453fd0ea39f38bcf44"), (20607163, "f4a9fd1fdc52255751d817dad71693b06116bc242b2c445cb81b533456864da8"), (22212031, "15edae34a1c7265b6db9810d0f96f58854c7bd68e152acafb9ebe9982a8a84a3"), (24015875, "a1fbcb10b928bafd293f873583f486101e12f113b47b1d7ce43ef71a71adcfcf"), (26321895, "9565e6a90f28ef7016df438041d32a376716fa4681391eedc8d2115d3de134f3"), (28713331, "bbb0eb3beb96fca3b53bcbacc6a78520067b242ef6c40ec1968422d8545217ca"), (30964759, "fd9fc7ac7177fecee7e1235bd314aa678b835165bbbf5e7aed93e3785896d2bf"), (32533587, "ea23335a473254129de67ce20b2c79b6a37e11dfe5ea60f3a2e89a9e193e428c"), (33962595, "988b9e6e9a6d0f654d7684acf501b8155073b39e95358658bf0601d3e3da4f3e"), (35564359, "e37968eead0c101e306a6330c54078145a6ea54bb0b3ede4567d1420e1b580ef"), (36390827, "160d451dee42416538ff1715bbef2abcb257e9a8a58fbb29d4cca5f5b025b238"), (37913579, "aa8707947868d8c31544d4668e34e06770e78e5c47de562aef5db574c8e78841"), (39411623, "c9f24127ab6316cac95182fd4edf04182dbee33b9fac7fc00319d19f51c655f5"), (40374891, "d8f9e5a5cb2d3b88491e6d3c3bf1b52061a85e115bce5eb2a00a8aa5dddcb44a"), (42716283, "da500f7f7280355a1019125b078ec186ff2e8208168775f7bcdcf98b4721518c"), (44561187, "947e385fa0e5fd276c2f5092fccd781d3075eec513590efa4bd0833f27058f96"), (45860919, "ee1e41e4741bae0f6fe6e42c66d482c5521e154bd8216a8b5c8ce5c8a59560fa"), (46991651, "4b9a98e1be5817d81a31960c33418f832e4f3dfacf972233309d2f299389771e"), (47830279, "d1d5305420e25bbf571d330e3ad4ac22147be887cc0924bc1083069a365634d2"), (49184947, "af86593cddba05515bd7b1818671c7f481b10251008bb5582295f8fcb95e1e7d"), (50531439, "b303078e0170fd60208a859a681d099a45964ef0e86d1d2267b159dfe6d8a724"), (51789323, "552cd97e5cfe0a6e9843c693f8dbda3db6cce1dc9ab26506772af371d95ae64c"), (53140275, "cc2f133fd063e30cdef62e08d7cfd17f65285de02365dbd86f17aede019d9c06"), (54201583, "27d1f29f793e911983998403aa713cb6f9db1b57252aad78b7c01ffffe0bd26b"), (55533219, "dfd15a3d8c33a0ddb0fe39dfad45ba8ce23756ad48752d15969056bfa92ab6f6"), (57255883, "316c4eb78d14f6ddd936332fd06cc88dfa56d35ec616709c5cdbc74ea1198673"), (58609815, "934bb4280f34b6b64326793740c159fdf81e751b237ab1eda2ee4f2fdb014231"), (59320995, "end_of_stream")],
    ),
}

BUILD_TEMPLATE = """
load("@toolchains_macos//:expand_pkg.bzl", "expand_pkg")

expand_pkg(
    name = "sysroot",
    pkg = "CLTools_macOSNMOS_SDK.xar",
)
"""

def _macos_sdk_impl(rctx):
    metadata = MACOS_VERSIONS[rctx.attr.version]
    outputs = []
    waits = []
    for idx, (rng, sha256) in enumerate(metadata.ranges):
        # Last range is the end of the file and there is no xz stream after it but we need to know it
        # to calculate the end of the last chunk.
        if sha256 == "end_of_stream":
            break

        # NOTES:
        #  1. Ranges exclude the header of the pbzx lzma chunks.
        #  2. We need to subtract 16 bytes from beginning of the chunk to get offset before its header
        #     starts which is the end of current chunk.
        start = rng
        end = metadata.ranges[idx + 1][0] - 16

        output = "output/{}-{}.xar".format(start, end)
        r = rctx.download(
            url = metadata.url + "#range={}-{}".format(start, end),
            sha256 = sha256,
            canonical_id = "dd",
            output = output,
            headers = {
                "Range": "bytes={}-{}".format(start, end - 1),
            },
            block = False,
        )
        waits.append(r)
        outputs.append(output)

    for w in waits:
        w.wait()

    rctx.execute(["sh", "-c", "cat {} | tar -xf - --exclude='Ruby.framework'".format(" ".join(outputs))])

    rctx.delete("output")
 
    rctx.file("BUILD.bazel", BUILD_TEMPLATE)

macos_sdk = repository_rule(
    implementation = _macos_sdk_impl,
    attrs = {
        "version": attr.string(mandatory = True),
    },
    doc = "Fetches the macOS SDK",
)

def _sysroot_extension(module_ctx):
    for mod in module_ctx.modules:
        for darwin in mod.tags.darwin:
            macos_sdk(
                name = darwin.name,
                version = darwin.version,
            )

darwin = tag_class(attrs = {
    "name": attr.string(mandatory = True),
    "version": attr.string(mandatory = True),
})

sysroot = module_extension(
    implementation = _sysroot_extension,
    tag_classes = {
        "darwin": darwin,
    },
)

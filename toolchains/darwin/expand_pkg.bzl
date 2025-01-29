def _expand_pkg_impl(ctx):
    bsdtar = ctx.toolchains["@aspect_bazel_lib//lib:tar_toolchain_type"]
    output = ctx.actions.declare_directory(ctx.label.name)
    ctx.actions.run_shell(
        command = "{bsdtar} -tf {pkg}".format(
            bsdtar = bsdtar.tarinfo.binary.path,
            pkg = ctx.file.pkg.path,
        ),
        inputs = [ctx.file.pkg],
        tools = [bsdtar.tarinfo.binary, ctx.executable._pbzx],
        outputs = [output],
        mnemonic = "PkgExpand",
        toolchain = "@aspect_bazel_lib//lib:tar_toolchain_type",
    )

    return DefaultInfo(files = depset([output]))

expand_pkg = rule(
    implementation = _expand_pkg_impl,
    attrs = {
        "pkg": attr.label(mandatory = True, allow_single_file = True),
        "_pbzx": attr.label(default = "//:pbzx", executable = True, cfg = "exec"),
    },
    toolchains = [
        "@aspect_bazel_lib//lib:tar_toolchain_type",
    ],
)

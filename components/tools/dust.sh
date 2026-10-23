#!/usr/bin/env bash
# Bileşen: dust — disk kullanımını ağaç olarak gösteren du

component_register dust "dust" tools "Görsel disk kullanımı (du)" ""

comp_dust_install() {
    act_gh_binary bootandy/dust 'x86_64-unknown-linux-musl\.tar\.gz$' 'aarch64-unknown-linux-musl\.tar\.gz$' dust
}

comp_dust_verify() { has_cmd dust; }

# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3 qmake-utils
EGIT_REPO_URI="https://github.com/GENIVI/${PN}.git"
KEYWORDS="amd64"

DESCRIPTION="Diagnostic Log and Trace viewing program "
HOMEPAGE="https://github.com/GENIVI/dlt-viewer"

LICENSE=""
SLOT="0"

DEPEND="dev-qt/qtgui
		dev-qt/qtserialport"

RDEPENDS="${DEPEND}"

src_configure() {
	eqmake5 BuildDltViewer.pro
}

src_install() {
	emake install INSTALL_ROOT="${D}"
}

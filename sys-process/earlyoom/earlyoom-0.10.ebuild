# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

DESCRIPTION="Early out-of-memory killer that runs in user-space"
HOMEPAGE="https://github.com/rfjakob/earlyoom"
SRC_URI="https://github.com/rfjakob/earlyoom/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_install() {
    dobin earlyoom
    doinitd ${FILESDIR}/earlyoom
}

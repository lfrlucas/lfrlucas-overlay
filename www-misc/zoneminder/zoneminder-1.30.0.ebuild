# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

# TO DO:
# * ffmpeg support can be disabled in CMakeLists.txt but it does not build then
#		$(cmake-utils_useno ffmpeg ZM_NO_FFMPEG)
# * dependencies of unknown status:
#	dev-perl/Device-SerialPort
# 	dev-perl/MIME-Lite
# 	dev-perl/MIME-tools
# 	dev-perl/PHP-Serialization
# 	virtual/perl-Archive-Tar
# 	virtual/perl-libnet
# 	virtual/perl-Module-Load

EAPI=5

PERL_EXPORT_PHASE_FUNCTIONS=no

inherit perl-module readme.gentoo eutils base cmake-utils depend.apache multilib flag-o-matic git-r3

MY_PN="ZoneMinder"

DESCRIPTION="ZoneMinder allows you to capture, analyse, record and monitor any cameras attached to your system"
HOMEPAGE="http://www.zoneminder.com/"
EGIT_REPO_URI="https://github.com/ZoneMinder/ZoneMinder.git"
EGIT_COMMIT="refs/tags/v${PV}"

LICENSE="GPL-2"
KEYWORDS="~amd64"
IUSE="curl ffmpeg gcrypt gnutls logrotate +mmap +ssl libressl vlc"
SLOT="0"

REQUIRED_USE="
	|| ( ssl gnutls )
"

DEPEND="
	app-eselect/eselect-php[apache2]
	dev-lang/perl:=
	dev-lang/php[apache2,cgi,curl,gd,inifile,pdo,mysql,mysqli,sockets]
	dev-libs/libpcre
	dev-perl/Archive-Zip
	dev-perl/Class-Std-Fast
	dev-perl/Data-Dump
	dev-perl/Date-Manip
	dev-perl/Data-UUID
	dev-perl/IO-Socket-Multicast
	dev-perl/DBD-mysql
	dev-perl/DBI
	dev-perl/SOAP-WSDL
	dev-perl/Sys-CPU
	dev-perl/Sys-MemInfo
	dev-perl/URI-Encode
	dev-perl/libwww-perl
	sys-auth/polkit
	sys-libs/zlib
	virtual/ffmpeg
	virtual/httpd-php
	virtual/jpeg
	virtual/mysql
	virtual/perl-ExtUtils-MakeMaker
	virtual/perl-Getopt-Long
	virtual/perl-Sys-Syslog
	virtual/perl-Time-HiRes
	www-servers/apache
	curl? ( net-misc/curl )
	gcrypt? ( dev-libs/libgcrypt )
	gnutls? ( net-libs/gnutls )
	mmap? ( dev-perl/Sys-Mmap )
	ssl? ( 
	    !libressl? ( dev-libs/openssl:0= )
		libressl? ( dev-libs/libressl:0= )
	)
	vlc? ( media-video/vlc[live] )
"
RDEPEND="${DEPEND}"

# we cannot use need_httpd_cgi here, since we need to setup permissions for the
# webserver in global scope (/etc/zm.conf etc), so we hardcode apache here.
need_apache

PATCHES=(
	"${FILESDIR}/${PN}-1.26.5-automagic.patch"
	"${FILESDIR}/${PN}-1.28.1-mysql_include_path.patch"
)

MY_ZM_WEBDIR=/usr/share/zoneminder/www

pkg_setup() {
	require_php_with_use mysql sockets apache2
}

src_configure() {
	append-cxxflags -D__STDC_CONSTANT_MACROS
	perl_set_version

	mycmakeargs=(
		-DZM_PERL_SUBPREFIX=${VENDOR_LIB#/usr}
		-DZM_TMPDIR=/var/tmp/zm
		-DZM_SOCKDIR=/var/run/zm
		-DZM_WEB_USER=apache
		-DZM_WEB_GROUP=apache
		-DZM_WEBDIR=${MY_ZM_WEBDIR}
		$(cmake-utils_useno mmap ZM_NO_MMAP)
		-DZM_NO_X10=OFF
		$(cmake-utils_useno ffmpeg ZM_NO_FFMPEG)
		$(cmake-utils_useno curl ZM_NO_CURL)
		$(cmake-utils_useno vlc ZM_NO_LIBVLC)
		$(cmake-utils_useno ssl CMAKE_DISABLE_FIND_PACKAGE_OpenSSL)
		$(cmake-utils_use_has gnutls)
		$(cmake-utils_use_has gcrypt)
	)

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	# the log directory
	keepdir /var/log/zm
	fowners apache:apache /var/log/zm

	# optional logrotate script
	if use logrotate ; then
		insinto /etc/logrotate.d
		newins distros/ubuntu1204/zoneminder.logrotate zoneminder
	fi

	# now we duplicate the work of zmlinkcontent.sh
	keepdir /var/lib/zoneminder /var/lib/zoneminder/images /var/lib/zoneminder/events /var/lib/zoneminder/api_tmp
	fperms -R 0775 /var/lib/zoneminder
	fowners -R apache:apache /var/lib/zoneminder
	dosym /var/lib/zoneminder/images ${MY_ZM_WEBDIR}/images
	dosym /var/lib/zoneminder/events ${MY_ZM_WEBDIR}/events
	dosym /var/lib/zoneminder/api_tmp ${MY_ZM_WEBDIR}/api/app/tmp

	# bug 523058
	keepdir ${MY_ZM_WEBDIR}/temp
	fowners -R apache:apache ${MY_ZM_WEBDIR}/temp

	# the configuration file
	fperms 0640 /etc/zm.conf
	fowners root:apache /etc/zm.conf

	# init scripts etc
	newinitd "${FILESDIR}"/init.d zoneminder
	newconfd "${FILESDIR}"/conf.d zoneminder

	cp "${FILESDIR}"/10_zoneminder.conf "${T}"/10_zoneminder.conf
	sed -i "${T}"/10_zoneminder.conf -e "s:%ZM_WEBDIR%:${MY_ZM_WEBDIR}:g"

	dodoc AUTHORS BUGS ChangeLog INSTALL NEWS README.md TODO "${T}"/10_zoneminder.conf

	perl_delete_packlist

	readme.gentoo_src_install
}

pkg_postinst() {
	local myold=${REPLACING_VERSIONS}
	[ "${myold}" = ${PV} ] || elog "You have upgraded zoneminder and may have to upgrade your database now using the 'zmupdate.pl' script."
}


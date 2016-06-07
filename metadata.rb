name ::File.read('NAME').strip
maintainer 'Luis De Siqueira'
maintainer_email 'LouTheBrew@gmail.com'
license 'MIT'
description 'Installs/Configures web things'
long_description 'Installs/Configures web things'
version ::File.read('VERSION').strip

depends 'build-essential'
depends 'poise'
depends 'poise-service'
depends 'poise-s3'
depends 'poise-fpm'

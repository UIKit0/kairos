rm Frameworks/AppKit
rm Frameworks/BlendKit
rm Frameworks/Foundation
rm Frameworks/Objective-J

if [ ! -d "Frameworks" ]; then
	mkdir Frameworks
fi

ln -s /usr/local/narwhal/packages/cappuccino/Frameworks/Debug/AppKit Frameworks/AppKit
ln -s /usr/local/narwhal/packages/cappuccino/Frameworks/Debug/BlendKit Frameworks/BlendKit
ln -s /usr/local/narwhal/packages/cappuccino/Frameworks/Debug/Foundation Frameworks/Foundation
ln -s /usr/local/narwhal/packages/objective-j/Frameworks/Debug/Objective-J Frameworks/Objective-J

#ln -s /usr/local/narwhal/packages/cappuccino/Frameworks/AppKit Frameworks/AppKit
#ln -s /usr/local/narwhal/packages/cappuccino/Frameworks/BlendKit Frameworks/BlendKit
#ln -s /usr/local/narwhal/packages/cappuccino/Frameworks/Foundation Frameworks/Foundation
#ln -s /usr/local/narwhal/packages/objective-j/Frameworks/Objective-J Frameworks/Objective-J

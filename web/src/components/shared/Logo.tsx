import React from "react";
import {cn} from "@/lib/utils";
import Image from "@/components/ui/Image";

const Logo = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
    ({className, ...props}, ref) => {
        return (
            <div
                className={cn([
                    'cursor-pointer',
                    className
                ])}
                ref={ref}
                {...props}
            >
                <Image src={'/assets/logo/pixeLaw-logo.png'} alt={'pexeLaw Logo'}/>
            </div>
        )
    })

Logo.displayName = 'Logo'

export default Logo

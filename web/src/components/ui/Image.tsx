import React from "react";
import {cn} from "@/lib/utils";

const Image = React.forwardRef<HTMLImageElement, React.ImgHTMLAttributes<HTMLImageElement>>(
    ({className, src, alt, ...props}, ref) => {
        return (
            <img
                src={src}
                alt={alt}
                className={cn([
                    className
                ])}
                ref={ref}
                draggable={false}
                {...props}
            />
        )
    }
)

export default Image

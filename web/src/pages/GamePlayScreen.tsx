import {cn} from "@/lib/utils";
import Main from "@/components/Main";
import React from "react";
import {useMainLayout} from "@/components/layouts/MainLayout";

export default function GamePlayScreen() {
    const {setHasNavbar} = useMainLayout()

    React.useEffect(() => {
        setHasNavbar(true)
    }, [])

    return (
        <React.Fragment>
            <div
                className={cn(
                    [
                        'flex-1',
                        'bg-brand-body'
                    ]
                )}
            >
                <Main/>
            </div>
        </React.Fragment>
    )
}

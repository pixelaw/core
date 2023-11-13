import React from "react";
import Notification from "@/components/Notification";

export default function GameLayout({children}: { children: React.ReactNode }) {
    return (
        <>
            <Notification/>

            {children}
        </>
    )
}

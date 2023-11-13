import Logo from "../components/shared/Logo";
import {cn} from "@/lib/utils";
import {Button} from "@/components/ui/button";
import {useMainLayout} from "@/components/layouts/MainLayout";
import {Active_Page} from "@/global/types";

export default function HomeScreen() {
    const {setCurrentPage} = useMainLayout()

    return (
        <div
            className={cn(
                [
                    'flex-center flex-1'
                ])}
        >
            <div
                className={cn([
                    'min-h-[306px] w-full',
                    'bg-gradient-default opacity-75',
                    'absolute z-10'
                ])}
            />

            <div
                className={cn(
                    [
                        'flex-center flex-col',
                        'z-20'
                    ])}
            >
                <Logo className={cn(['cursor-none'])}/>
                <Button onClick={() => setCurrentPage(Active_Page.Network)}>Connect Wallet</Button>
            </div>
        </div>
  )
}


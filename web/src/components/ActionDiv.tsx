import {cn} from "@/lib/utils";
import {Card, CardContent} from "@/components/ui/card";
import {Button} from "@/components/ui/button";
import Image from "@/components/ui/Image";

type Action = {
    img: string,
    label: string,
    onClick?: () => void
}

type PropsType = {
    label: string,
    actions: Action[],
    defaultMessage?: string,
    selected?: string,
}

export default function ActionDiv(prop: PropsType) {
    return (
        <div
            className={cn(
                [
                    'flex flex-col gap-y-xs',
                    'animate-fade-in'
                ])}
        >
            <h3
                className={cn(
                    [
                        'text-brand-yellow text-lg uppercase font-silkscreen'
                    ])}
            >
                {prop.label}
            </h3>

            <Card>
                <CardContent>
                    <div
                        className={cn(
                            [
                                'flex-center gap-x-lg'
                            ])}
                    >
                        {
                            prop.actions.map((action, index) => {
                                return (
                                    <Button key={index} variant={'icon'} size={'icon'} onClick={action.onClick}>
                                        <Image src={action.img} alt={`${action.label} Icon`}
                                               className={cn([{' border-brand-yellow border-4 rounded-full': prop.selected === action.label}])}/>

                                        <h4 className={cn(['text-sm', {'text-brand-yellow': prop.selected === action.label}])}>{action.label}</h4>
                                    </Button>
                                )
                            })
                        }
                    </div>
                </CardContent>
            </Card>
        </div>
    )
}

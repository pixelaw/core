import Image from '@/components/ui/Image'
import { cn } from '@/lib/utils'
import React, { MouseEventHandler } from 'react'

const PIXEL_STATE_SRC = '/assets/placeholder/pixel-state.png'
const CANVAS_WIDTH = 256
const CANVAS_HEIGHT = 256

type PropsType = {
  onMapClick: (mapIndex: number) => void,
  visitable?: number // Number of visitable maps
}

const MAX_MAPS = 15

type VisitableSectionProps = {
  src: string,
  onClick: MouseEventHandler
}

const VisitableSection: React.FC<VisitableSectionProps> = ({ src, onClick }) => {
  return (
    <Image
      className={cn(['cursor-pointer hover:border-brand-skyblue hover:border'])}
      width={CANVAS_WIDTH}
      height={CANVAS_HEIGHT}
      src={src}
      alt={'Lobby Canvas'}
      onClick={onClick}
    />
  )
}

const NonVisitableSection = () => {
  return (
    <Image
      className={cn(['cursor-not-allowed opacity-75'])}
      width={CANVAS_WIDTH}
      height={CANVAS_HEIGHT}
      src={'/assets/placeholder/default-pixel-state.png'}
      alt={'Non-visitable section'}
    />
  )
}

const LobbyMap: React.FC<PropsType> = ({ onMapClick, visitable = MAX_MAPS }) => {
  // this is to force the image tag to refetch
  const [imageSrc, setImageSrc] = React.useState(PIXEL_STATE_SRC);
  React.useEffect(() => {
    const timer = setInterval(() => {
      setImageSrc(`${PIXEL_STATE_SRC}?timestamp=${new Date().getTime()}`);
    }, 5000);

    return () => clearInterval(timer);
  }, []);

  const renderMap = () => {
    const sections: React.ReactNode[] = []
    for (let i = 0; i < MAX_MAPS; i++) {
      if (i < visitable) {
        sections.push(
          <VisitableSection key={i} src={imageSrc} onClick={() => onMapClick(i)} />
        )
      } else {
        sections.push(<NonVisitableSection key={i}/>)
      }
    }
    return sections
  }

  return (
    <div className={"grid grid-cols-5 gap-[0.75px]"}>
      {renderMap()}
    </div>
  )
}

export default LobbyMap

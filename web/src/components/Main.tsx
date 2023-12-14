import React from 'react'
import Plugin from '@/components/Plugin'
import { ColorResult, CompactPicker } from 'react-color'
import DrawPanel from '@/components/shared/DrawPanel'
import { useFilteredEntities } from '@/hooks/entities/useFilteredEntities'
import DrawPanelProvider, { useDrawPanel } from '@/providers/DrawPanelProvider.tsx'
import { useAtom } from 'jotai'
import { colorAtom } from '@/global/states.ts'
import useAnnounceAlert from '@/hooks/events/useAnnounceAlert'
import useUpdateComponent from '@/hooks/entities/useUpdateComponent'

const FilteredComponents: React.FC = () => {
  const { visibleAreaStart, visibleAreaEnd } = useDrawPanel()
  useFilteredEntities(visibleAreaStart[0], visibleAreaEnd[0], visibleAreaStart[1], visibleAreaEnd[1])
  return <></>
}

const Main = () => {

  //selected color in color pallete
  const [ selectedHexColor, setColor ] = useAtom(colorAtom)



  const handleColorChange = (color: ColorResult) => {
    setColor(color.hex)
  }

  // subscribe to torii messages to announce alerts and automatically update the components
  useAnnounceAlert()
  useUpdateComponent()

  return (
      <React.Fragment>
          {
                <DrawPanelProvider>
                        <DrawPanel />

                          <div className="fixed bottom-1 flex justify-center w-full">
                            {/* eslint-disable-next-line @typescript-eslint/ban-ts-comment */}
                            {/*// @ts-ignore*/}
                            <CompactPicker color={selectedHexColor} onChangeComplete={handleColorChange} />
                          </div>

                      <Plugin/>

                  <FilteredComponents />

                </DrawPanelProvider>
          }
      </React.Fragment>
  )
};

export default Main

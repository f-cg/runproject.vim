function! GetConfirmChoicesString(choices)
" TODO: 适应选项数量大于10个的情况，适应ascii码从49到126总共78个选项,
" 增加正则表达式应用于不同文件
        let id=1
        let result=""
        for choice in a:choices
                let result.="&".id.choice."\n"
                let id+=1
        endfor
        return result
endfunction

function! SaveAndExe(cmd)
        if &modified
                execute "w"
        endif
        execute "!".a:cmd
endfunction

function! RunDefaultCmd()
        let defaultcmd={'python':'python3 %', 'javascript':'node %', 'sh':'sh %', 'html':'firefox %', 'c':'gcc % -O3 && ./a.out','cpp':'g++ % -O3 && ./a.out'}
        if has_key(defaultcmd, &ft)
                call SaveAndExe(defaultcmd[&ft])
                return 1
        else
                return 0
        endif

endfunction

function! RunProject()
        let level=10
        let runcmdfile=".run"
        while(level>0)
                if filereadable(expand('%:p:h')."/".runcmdfile)
                        break
                endif
                let runcmdfile="../".runcmdfile
                let level-=1
        endwhile
        " 找不到run文件
        if level<=0
                if !RunDefaultCmd()
                echohl WarningMsg | echo "readable .run file not found!" | echohl None
                endif
                return
        endif
        " 找到了run文件
        let runcmdfilefullpath=expand('%:p:h')."/".runcmdfile
        let content=readfile(runcmdfilefullpath)
        " 去掉注释和空行,注释以#开头,不支持去掉放在命令后面的注释
        let file_pattern_match=0
        let commands=[]
        for line in content
                if (line =~# "^\\s*#[^!]") || (line =~# "^\\s*$")
                        continue
                elseif line =~# "^\\s*#!"
                        if file_pattern_match==1
                                break
                        endif
                        let file_pattern = trim(trim(line)[2:])
                        if expand("%") =~# file_pattern
                               let file_pattern_match=1
                        endif
                elseif file_pattern_match==1
                        call add(commands, line)
                else
                        continue
                endif
        endfor
        if len(commands)==0 && file_pattern_match==0
                "没有指明匹配规则并且命令列表为空
                call RunDefaultCmd()
        elseif len(commands)==0 && file_pattern_match==1
                "指明了匹配规则，但命令列表为空
                echo "commandlist is blank"
        endif
        if len(commands)==1
                call SaveAndExe(commands[0])
        else
                let choices=GetConfirmChoicesString(commands)
                let choice=confirm("Which command to run?", choices, 0)
                if choice==0
                        return
                else
                        call SaveAndExe(commands[choice-1])
                endif
        endif
endfunction

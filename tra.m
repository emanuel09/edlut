% This file plots data in tra.txt, the log file generated by the function
% test_simulated_robot_dynamics()
firstentry=2;
firsqout=firstentry+3*3;
firsttorque=firsqout+3*3;
time=1;
t=load('tra.txt');
figure
tit=['pos';'vel';'acc'];
for magni=0:2,
    for joint=0:2,
        nvalue=magni*3+joint;
        subplot(4,3,1+nvalue),plot(t(:,time),t(:,firstentry+nvalue),'b'),hold on,plot(t(:,time),t(:,firsqout+nvalue),'r')
        if joint == 0
            ylabel(tit(1+magni,:))
        end
        if magni == 0
            title(['joint:' num2str(joint+1)])
        end
        %legend('desired','actual');
    end
end
for joint=0:2,
    nvalue=3*3+joint;
    subplot(4,3,1+nvalue),plot(t(:,time),t(:,firsttorque+joint),'b')
    if joint == 0
        ylabel('tor')
    end
end
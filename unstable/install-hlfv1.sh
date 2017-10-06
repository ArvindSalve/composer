ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh
./fabric-dev-servers/createComposerProfile.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.13.3
docker tag hyperledger/composer-playground:0.13.3 hyperledger/composer-playground:latest


# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d
# copy over pre-imported admin credentials
cd fabric-dev-servers/fabric-scripts/hlfv1/composer/creds
docker exec composer mkdir /home/composer/.composer-credentials
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer-credentials

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� ���Y �=�r�Hv��d3A�IJ��&��;cil� 	�����*Z"%�$K�W��$DM�B�Rq+��U���F�!���@^�� ��E�$zf�� ��ӧo�֍Ӈ*V���)����uث��1T��?yD"�����B�y"��H8�p�� FBb�	����X64xb���Y��=��B�����"���,dv4Y;����L�6�d���v�O�C�뤬�k#SGj����1�b�mlږK x�-l;��V���fb��{��8��R���a>���� \?Q�h���M����UhC�2�aySB��W�2�<�	��!d�jK3��ab]�+!�D6��?,WJ��j�bc����n���h@�@��;���'�ٴy�Rl2iG&�i:Z<��7m����,��,��ڶ� �ވ�@�U�/,�`�*^kqb���^�����BC6��MO%��A�Zخ�Bء��x�T�IXn�ϟ�!-��i��f[�	<�~t	[m��D��0�)��3łQ(.[��5(ZP�e��IZ�Ь����"\e��2o��n��+Џ	���K�Dd��3�ϟ�9�������>:Ȳ+Ń�e�ԅ�#]��C��C���C��;wS(c"�G�o��G����.6�̮��ݳ��F���-��]�.�����W�T��Q�O�4��mP'/���(��`("��$w��'3���f�������k_�V�m���_1��I��(�r1*#k���@U3Uh58;�� �|(*��j&՘��u\.흗+�D��σ-|�=hwU�)p�cH��,_�.�5����O����z��X���3��&�#����i���Is��Ġ��������s���l9v"�~�vK��f��F&(�2�Й���#P�&٫u����P����ڎIwf^�mS�@�v�6ĊLD�k66{�Ӏ�	O]����A�E6��Ié�Ml`����n�i}�۔�б؜>sJx5��隂��-�i _�;���IdG��v��XÃ^Vu�4�����:���o��� �aEc�����o���h�ꃦ��:��;z�|�=�~������h�d!�7�.J�O!�?8O`�����>����}D�{�z2�Cj��AT��M���?Yד���}]�%�_�<���AA���_���3@�<Psv���AS�u ���;�"`:����K!�V�l����9�H�}��2m�>nqZ����H<��vσ�)I���40��I{�6$��l����� @6��z-�~2�\M#�'���^��4�f�`��F���YL'��{Kfh�."$�3械9;u���arޖwܭ�����X�]ib��]�;���l�DdfYu�#���{TE��S���&dl~=���I��'����`Ǌ���=r!B��h6�D��b�g7�D�8�Q)���ZXHG��Mi �<�#�9����ɘ|�d#ޛu�ޜ�1~����t�<�~"�פ�U��s�3<ʞn`���k �&��ׯG�S-ݩy}���C���#*�����_*̰��������"ᨰ������ϗ3�������`tZ�����j�����s�;s�����iW��c&�y�z�V]'�1MJ�h��`��%���OP'\y/[:/%�٣���D7!�����yvEog����r��s�}W��M��b6q~�*����������9�@��cX�~E�t�i�ܰ!�I#��d�]/��C����$�V����G��t�r����\,�����a�<��h��.�����b��֍!L�����_h��z'�b^>gQy��߁w�����<7���$̹����'�8�Ӫ"�?~|��R ҺtN�tzB'�i%LFد�<���i� (�$�_�����s��`'�E������
ѵ��X�_6���A�~��2��´�E��
xx��}����h��f��u��MT�.�����z�}�u�3��_���ߋ����:�s�|���^\p���o������'(x���M�(Y�������݅c���M��4��
�MͰ���4T����u��G6}���N�'�D�\L����0��k��������D�l������}��%=��O��e��AF���!ω^dd�~N�z�J�b��6UB/Ǻ/�Ign�L�H�;�NS�
�i����gf�����=��:�
�M�'�.����L����Xt��U&^+����S6p�;�S�t�O����@�4�.�on������G���P��k���p�J�#՚+��G�"bú�K!��B��z��h��8P����f |�_����x'l��T��ީ�(�:Qe���V���L��RdJ����Z�W� �o5� �eli����N�A����7�3?*8�`W����BK�#��/EC��ߕ�}��Q^�sw����,������=��:�4�	{��0�X��$���<��Ҟ� (ipn%�&I ���Ѐ7�9���*D��� u�?�r�FO�E/n�.�x���)J��K6`�5��gز�$#^2/i���c:E�D�&�,���%���ac*5����O'˘�c��X.�ɡN%�y~�w�K�f�Y�?e^���<3|Hx��6�df]]�h@��Bdx��J���b�f}A��y���h�Oh����b4���������������6�/��+����?ᰴ��\	p��5w�}���o��������_��0e~�	���"I��vMQ��Z�&)۱X�V��`"IDRD�Uc!I�R,����v8X��7��k�/_sӄ7���Nn�u��/���6�������'�>�6,lښ�����6lT��}��&���W�|5�����Y�;k�_6����mp���H��~"8sb�ͫim�a�)A��a�8N�h�1�`����v}��+����y�wj���?$���j���n�6m,�����/E��Z����=�xQ���TR6�i��қ��xX#���x��fj��R~皷�:=g˲���#(�(AXP4R�	Jt;$l׶c��H�m%&C��Dd[�����Q��QcP��Q҄6�v�+����t8>
�T&��T��Mgr9�J��l6��H$d%Q��ٸ\��sh�_��@<��o�N5�B7Q?����Յ�"�]�*u@(�͌,VR�F.q|��L]��x=LH��|���[����.�r�}�����ϼ7�V�9�W����LY~�b�r*�]�����F�m�:+�/�A�r/)C'WN���Ak&fw���se����s�pX�Oh�+e�x5W����i�PȤ�o�+W�r�L]"��/�<9�(�p���:����/s��F%�v�����I���_T�R�\\`r�{R8)��$,��0r���2i[�\��|�Z������2���L)'��z*�Hx���=Y��񌳽/���e��;��h��v�r�#I2'����q�<9���J����i��4-���E����v��Z9��9�R�L��Q.�r�Dւ�VMvS�@�@�x���st�����\�N���KXtTj�[h��r6�2Ϡ�g���Y<hv�[�-"Yxxh
�t$�߄��;9GFV0!u9��$���d�"�D���Z>E�6���Ob��q�2�̆Q�8�t�c���g��~��oz*N�T���\,��o�s{GP�z	)���JQ�}o0�O�3Ā�����?��6���|$3������/�nnȡ/ �bD�<�ԟ	�c{޲�R�D�_����}>��װ��_��M��	�bx��󓎊�cb�~ꔕ>�r�����"�]H}�B�.���A|k��֬F�rg��Pߢ|�D�;z:����~�:�r%d�hvV��/�s��U&�/���VB�/��������^���:
W�����h����a�"��w��+����%�rC�ws`�{�9�˰��M�^��U�g��N�s}O~�?8�������%~�M���t����y�	�0<
I�%Y��)횩t���7�˓��D��ކG��S��ҹf
)N��s�.����-��4�l�n�QW<����k�r&�������瞵�|����6��%5����[�J���܌�K�����g ��=��Ef�9��l����H�,PD�/T?��FY%��ܴ�>�,��!s���<��{8 ��C7�Ь[<��$�i��"�p�FuAC�b�hA�i�/j	Xe^�Kc��?-��)=��G��y�#8� H�Ԍ0_���mJ�/���V�����,�*�q�� QU�#��ӏ�֕я��a�v!�㝇g��xo��4��QXxГ��ߺ����ȏ8w:<�����WdK�h��t4�$�X�ݫ���;h6���1���4���cz�\C혌�� ��?^h�.��؅˥D�@��6z�J�K��ÆM/ B@ӄ=� -$��MY�v�؀QY��mi�K��b@L��z��lJ� �,���F�[��`�O��AQ�W�����{����� s��76�ʀ��5Pn5�Mh;�AL|SSU=C��@�&�d|�����^���Mޙ����__���������>������J�5����v���L�b��c�����P""��
��jSF� ��4�Ӷӫ_Ø�i-wQ��Iɜ�_w(�+Np�Q��&��ŵ�M��}0��<�"�gf��МS~�x�e ���_�k���{ѓ
D����&�T	�4��A��EèY���2ƃC�ߔ�&��5���o*����I`ǰ}��N�C�_o$���n�8�Cf	�&���ʽ�M���׆�.�f�~���y���CW��JU�m:��ҧ��9X�-���1��nd�]eH'�&�n9�C'�(Ew,"EDW��&�*�=O����i�^7Q��vG��rM�e�N��!�C���Ն�X������8�<�〻l;n�>W����`$2D��d>�>���������/>�8U,�[���{sP��Pj[T����CUevN���<R��p�h�&����� ��1Y�����(����k�uK��=Msq7=Ej�A����F}��#��\���c'qn���dq��N��y�؉�,P�@H3�H�b7#�!1�0,����b�!v�|�q�]�[�sZ}�^����:���ls�O�����<~%��~�g�?��.�ŷ'E���?W������o���~G>Ǒ���������譣C�����5t1�ʟ~�Bѐ�H��*�X�
G�r�)IaM<#íA*dT�	�lK�!��_H�x���~��|���~��W~������䏞��8�{�],�;X��G�^�h��_����� ���z/��� ����?"_J���=|�0�O��v�m��{��n��b�S.Z�����n4Z>6�t,��z�l2,}�t:��~/�/X��,�
�-��W!>tUC`Zv�P؍��Z3�XsA��ٝ�V&6�.iB���B�@
��d=[��
�3DH	���N���HkQ(
&g���1[��ǍAl�h]�X74|��L\�����ns����L(�̈́	3�rs�k�T��*n6��i��B�4���E�y�W/��3^����3l��׏��iz���y͠:� S<���S|id�|�k��t"�.T���~�.�쬄��3%Y,SVF�+e�B3Y��"��)�����$����5?]O"L�A��	3�v�I�ْC�Y!��B')�yD�:)��"}.��F�4��05+��"S����yx���*�4߉/&=T+��.q�@汨F.��L��w��.����43���dMk�IJ�UKe�H'�Qz6nRbnn�'��X9�����������^�Mw�^"w�^"wE^"w^"w�]"w�]"wE]"w]"w�\"w�\"wE\"� ��0�.�f)E���O�J�Õ�Rb��9��7��x1���8��60�.��q/jgE�s�*'�K螻�<R�[��۩����@���������A\�S붗yj:Ċ�Hz�3D渁gC�iT�r���f	~����ܔ	�jiZ=G0��S�DY
7��&��	N���Hj��j�����&�'����8c+s�ٲ�#t-��Itoi⭈�Sf�[87/T?:5�r82�1J�a�C�9�)�fbX�vb��(N��<]�D��eS}BᒹӊJ��ܤ�Gd��J�~�̢Ԁ��˼[�w��ہ_8z=�A�(���G�=z��r�?� ���u���n�}���o���&���G��Z>	�s������G�N>��^�:5]���/z�����x#�ׁ�����[�(������+�o<��c>��������<��+EYfi�2YZ�|ވ�r��2y���r�b��ۭ-�/�/Z�'X����8���-3a�3I��Pr!���Ky������\�-�
&�qD�ilJ����]	���o� �D����tZ�������x�BH5J����Ȕ�S�cv�W������T��ln���z�X`��z�mQt|�TZ�8i�F�֣��6H�;*?NWFx�Dj"���L�x����+�4k9M�S���4K��� #�@��P!iAf;��3R�[T�F;*]n'���HĐ��sK�l=Qu�4_�/�SdMQv�)�e8Z�՚���k�&.v˃A�D�	�k9˂�`d-�~�l!���9m�����]f�tÚrܘ3U���-^�J�d�G����ǿu%�ā����B=��|yP�����δ[\n�����e��]���4�K���� �u�#�q��"��"��Y���j#�o?c�gf��e\vGn��.�#����u�{����7�ڴ���
G�[�e:��Ɇ�Vyc֑�|&Oԓ�8�Vla8,)�zܯ���X�.}6�0Ōb4��í��y���è���F��J��lV��*\�ڴe�6��M��6���x��Gt�:��Sȇ�N"5�u���8R힟Z{:��A�|�W:�dZ�R�%��b��҂4=mբy%٨(�T�/��1�.Efi�	�ys �7.5/E�a:��&S�v?�Ry.B�[Åip�X�1#�x�E��³��y%OdE�H+E"dg��xXS#S�1�+��-��l��U$#3I;�d�p�G����4�2An{�*de_�L$k;�*�"0�]�����W+�Rz*�+����X��R�C��Vp�	���c.���*�5
%�Cp�cq�K+ճ(�<Ki���M��et:S��;�
q5��)g��y�)�����E}h:��*��=����	җ�BJܐ��Ba�nF-E�N���|��r�J7D�V����l��5�T�Q���a2j��4�cSi�4���%��P6�-�F�U��r���.c&�.���_|˲���w��M7��ٍ�/Z���.�����<tlѢ���*8r3>�e�g�i�2ԧ��+����7��6�<F~���V��.��{����ϟ?�?|�<�����#ڎ���D� V�>E�΀oISeۇ�]�@\ӛĕ^)�y�y��t���:#��� ���#2�q>A~����)P��8�8uG�k��{�y䁳8�,O]W� x�|�`���ҡG��"�2+G�k��t�t�� Od̯����������H/���G/8���A����ד ���
�;��ts�����T�
�/�Vf��z�;�0V%���4���Ŏܸ��;
���4���3"�_���926ifw��]���H���I�S�k�*��9?�t�l�㧫���3�z�폭�U^Ѣת����U�ɎN��h���s�cj|oo==VG_Q�lH��z?<�HPP� !=����%-�8F�G10E�6��'
,Բ� z& 1�"v*�2H}c�]\ �3�w�ؤaв�S�� �fq.���Ի��&������ �˩O��/O��jNW@���+��V��&>$�MO��`������z�_ g�ADVТ3��1���X뭭u�v �w�W���h~�ʬ��A�|��,] R�̢�'���g�*�L�*�?Yu�b[�h���%���q��{��юW�]�Ip��:�z�"�gm�}��e�tb���2z��$��6�O�aKK�I�8�j8���jQ;�+��@��z!�g䊉+�������ԃ��?�0Ӱ�M���	�����* �.6��u��~�_�/�LF�}=w�_�1t[=:�� ��`S!z,-{�Q�k28� ނ��>�)OB�P��Zm6����6o(�� )�O◧q���粫k@W�g/"��B�m��p~в���dM`e�%�s%k�hٺ2�^���-%O�{��Q�� 8\�a�n]\*��/ ���P�$U�/cX%m �cp.�bz��v_�a�Nv �ݶ��^q�Eo���#�c��� �	����ӔT�=rQ�@�J�&(�񟅜	}�vp��,�]� _�.� Q�6����*�u�ii�~��@����`WV�ce2����C�&͝�\2�o�nZ�<�t;h�Y�$�s�>�n�	r�#��[�E ���D�4kX򪋫�=]�8�	�e��X4(0����.�lto�x����c��� �ކ�8m1���j�i"�-B���W�Z%kݶ�����jBH��:3r
����23��z�:��:�k�'ش_@���1���^�U�͉�	�C��	�z?붉�ֆ�Ɖ�S�9�a1b%)��������_��$�-4egCi�@'(�w���w\qpl��b��Iߑ���j�����
$��܏:�����������������m�����+���b3�'�`��}$��!>!>A@j˶Jv�ܰe%�vr��h �oó�g���"?��g 2�3T1Z�����Q��+\����*vt��R��Y��\��ծu��'���ӱrEC�\�f�H!K�I5	Ij���HdH	�m�j�ZJ�#m\��f��?F��v���p8�H%��}[�����DX�ì�gN,�*�����l�Ƕx�O�'O�Pa̐k�bǂxf��W7��IM����&�bY�qB	�0)&IE�cJ�RQ%$5eBB
Y3�)ሂK��X|Ҵ�����c3�D���̲��o���7�;�$�亣q��	Ovfߓ�E�V�]����wd��cw���msE�+ZT��\�Μer�W�2�d�9�\��/�\�f�"W*=àu�]��[�K'�r�3x�E�����_pa�A��P���3���U�A���.��{��U@@�[;�3�Π���vF�\�'-���i���Z�3��b��-��o�A�6io��;]k�nxl熉Bw�!���V7g�j}��nz��0�b�ߊ�y!��sEy��&��W� t�>���l<Ǯr�<�rL9���"�qY6����P���(
�Y�3i�N�CǶz������Yy��?��m�&<Z�����ZES���e|�,ˉ�\�T�F��e�3����F�X�>���d=�k��bj�g@�=fY-�&��%�9�'K�4C��gq�e.�ϕ�)�q����N�1��E�/�A=�-�O�8��L>kK��\����"�xc0��EL���:Mݝﯡ���,���vs��:߲]��d�X��`��2V��~��0���{�F.u���N���ͮ��;V�ߊw�#�9+3V���@!t����3��m����zq`�&�f�_�$9��G���o��6n��!�|'뿏���KF�f�CD?��>�+���ķ�c���H/��MoI�	zH{H�X�[�*t��{I���'plS����A��#�K�ß��i�ʦ}��K������_ �����hhh^���f��W��#w��:�{I���9&Y����E�v$*����l�Ȗ"K�X$��*�EۡV�����pTib���	�u��,��j�Wa���m���k/�g�m�ɼq�O�}\S��:iet�:G�+b�M	�;�4��u%?��8ɍ��$P=��E��"m.U���rH!2��@��E��-�=�ޖ�����y�?����ޤS)N�Z*^	a1eV��a�;F5��؟�����O���?���_z���Ɔ��8iw����������H���'�������Gڗ�� x���ʧ��?�����[�d$r���H�,�R����+��� ��]��������
�x ��D�O����.�Ij[�S����j��G�Jti_��2�g����?:|��G�?���;Q����+�{�j���w��IEE���w1�8�����O�X��N*U�r�U�J%��f�}���	Gu�Q���ΟB-��`��?JA���B�_�������O�� ����?�V�:��v���C�o)x��7������)u���e��~��:!�-�\���,*���5!��Z��O�gv?��!ZG����u����g���Of��������'�4p��
�\f�P�ga���f����ϭ�4�T���sŖ�U�
�|��5��Nc�!��ҏ&�͏a{hӗo����{���O�G�>��~�e29��{�`�[w�F�.���>�$9����l�nɿ��ϻEse/��ԕ#m��8vE��gӻF��b�ҴP{�HTړ�oS�{��~ȷ7,L=���˝���%#�LcG����L�Z�?��W�迧Q� ���_[�Ղ���_����U6jQ�?�����R �O���O��Tm��@����@�_G0�_�����������+�S��e�V�������Dԡ���������u������u­c>��3WUch;�~��+��������ϝ�謉_�#o�����2y��'�[���P\i�����Z1ܥZ����.�8)�����=EP�Nb7�Θ������R�7ۛ!�뚜=���_����������wD��s���_��+	��6>r�㿷�o^~��P�J�x����X��.i|JI��Ηڔ�	:!�Ͷ��Q����u"��p暤 ���n�Prd�
'��KF�h�O������������+5����]����k�:�?������RP'�f��3
|����<��P��I���g}��	�f|��|��i�"8�CC��qԁ���C�_~e�V�uq��d�l5uɒ�=�
y�A�΢�M���_����͑Ώ�<?�(��U�,�LL��t�sv��i`�M2_o��v�e�K����s�^ڌ���?l�'�:���^�����ա���~]�JQ��?�ա��?�����{����U�_u����ï���![Un7㈉L��g4�r����d�p��O�a�n���#�<�A3f\���].ջm�(�sd���/�'�D�:�2B?&�=2�U.tf��e��9�g�`l�<��M�s(��ދz��q�+B�������_��0��_���`���`�����?��@-����?�W��Nq��=����Ȼ�a=az'	�c�4������|p��om�rQ[�9 yz�'� @��g�p��~{���C��\x� �8�rh�|���'�Z$|�.��4ZMA��J��Y��4l���7"}8�1ꄗ�C�]דv�)看z3vN�o֋��s$r��n�<�k�����g vK�5�R�Hn	���w��]�ӌ�A���#A�X��ﺡP��HaY}�'�~����ib���`sMh����r&J��R�""L�������dCT䑊��C�j���[�Bc:U;BOg��� 	=�nGd�-�=>!�ͤo�E��W�u�u��~���<:	:���VW���z/�A�a��G��+���]��/ʸ�o�������`��ԁ�q�A���KA)��~�EY�����O�P�> ���!������`��"���0��h��<%Y�	� �C�G]�u]�&��AY�	���A��,�L����b秡����_�?��W��:}�,�Ԧ��c�{�hċ'I�ɹ���kdbP����9��IɃ�i�BK6J�A�{l�Cd�&�~��ݤ���������6�yFͶq�7މ鴬]%�-��}/�p�������S
>���U?K�ߡ�����&0���@-�����a��$���n��!㽎 �����/W��*B���_��?h�e����4�e����k������f�7�ASh��	'�re���E%�����e\�#?3�}}����k+����<���S��N�� o�~��z��<��6JzGF��Su����4G�C�+t6��xĬ��lꪼ�r3�)�q'�%V7%ӂ��vH�܎ruaYBO��6r��J�Y��kۉ�w�s��A8d7�-su�M�f�+n��C���x�ꐮ{��ʎxM�E��L5hD���gMC�u�s���i0�B��fl�#�(�H�LJ����=I+�SWVr�c&2i����g��c��C��c٥������ߊP������
�����������\��A�����o����R ��0���0��������,�Z��������������ӗ�������$��e �!��!�������o�_����!��Ъ�'�1ʸ���I��KA�G���� �/e����-T��������
�?�CT�����{����Ԁ�!�B ��W��ԃ�_`��ԋ�!�l���?��@B�C)��������O����a��$�@��fH����k�Z�?u7��_j���R�P�?� !��@��?@��?@��_E��!*��_[�Ղ���_���Q6jQ�?� !��@��?@��?T[�?���X
j���8���� ����������_��/���/u��a��:��?���������)�B�a����@�-�s�Ov!�� ��������ī���P���v�2�7C}�%Pv�r��'=��H�/$A������.�2.�a��r.IR����z����4�E�S�?*�K�U����v�Rq��T�
m4w�ހaD(�佞�&q����8}~���$�����jI�_Uc��C^y~�;��a��T��E��F1"��*ixa����}6�ԙj�B�u�v����N����C����d�=�c��:�y���K��'U�^3�����ա���~]�JQ��?�ա��?�����{����U�_u����ï��>�Q�ƾo��FM�}�7��b���_���i�Sy��V�ܛs�M�߰��n��� ��E�C�*Qx�N-e۴�����|����v�դA���f������f1�˔��{Q������������}��;����a�����������?����@V�Z�ˇ���������?�����?���q,��91�ő"����_+����Y�]��$8���Ro�X"���#Ҟ�[���lH�%��I�3M��`$H�v+�,���z�ڽhL�Ì��0R�/�=������^D�dA���gZ;ɑ{m7�^^�k��ӥ�����rM��vB$�����_���@w�N3���>��c�b��B���E�I�0��N�jv�,��l�J�9y�����Ǽ��#b6P�n�8B֧�ə���h����ǂ2���zn�`A�\���I�v&T#<l�es�I)fk�����I�OvA�{}x�;~���28�K�g\��|���'.��_�P�a��O��.���Jt��ڢ�����O��_���8���I��2P�?�zB�G�P��c����#Q�������(���{����F����A�8��]B�������?Zo��?D�u�4��ώ�t�Q�^�
��Z;������q������K�7߿�.]M�n���j]^��kj	��ؒ��[B�8����u�!�ԙ�a�#_�FF�́�(u5^��Nn��T3~6�٣c�J��E�J1w�s�ToR¾���ʶ�ѼM�
�p������'�nѲOVޓ��No�����B4��_�?��~��7[���NS���� 
�ݛZ[�!�M��!6�6�u�͎A5!~��tI�c�r�#��K���>��&+`٥�t��`4���L�Ӏ?�r�S!���H���n�Bn����]{�&Ч�Q��ܔ���r̙}i՗_��Z�?�n���%���x���ž�H��f�����I��f(��8=��Ip3�`<ڧ|4�8�Q`���P���~����`�������f|���A�<��`7y���8�ݓG(e�sG_����ʟ�
��rU+0��^|���j�~��Ca$�e��c�{��_)(���_�Q��������h���-��W\�?������c��ba �Ϻ�'t0���?�*������@��SO���`C>��-���!?��]�?���D��׿�~7�y��g���B��:́�nCJaka = �G5�֘�_��7�4�5:pbu�Ӽ��B?K����|����d��F��vGW����w��������:�f����G�ٻ�d�+��,M[f2��tY�*�����Ix^&m���z=�P+�0�rҿ�(JyM#[/��G��Oռ�*E3C�a͹�	��*l8�Mo�,�d�W���ܝf���}����G�?��[
J��S.�~H�,�3ǯ?��|E1a8�<��\�e����]���8F]�X� ��Q���q��x�����|�J��ա�i��vN9q�4\��9�v���}�7N��w����e�U� �-��������~��c��2P�wQ{���W������_8᱖ �����!��:����1��������w�?�C�_
����������ƴ�T{mh�^Of{�,:̇���/��5A��?�^���*����Gi��o!
ȷ�@N$K&4iz��Y��g}�\S���=��r�ֹB>ں�u����+���������ض����N�[�n��S'�
Pl�oo��� ��S�_h��Nt&��4���S��� ��{���Z�Y�V�x��ʯ+ᅽ��pR���<
�q��mm�y��S9�Z�Y��}��@Vc�;��񩶪0��{0�Y�����iۮ�ܒ#-WĬ%p���jV�+%�L�)�������� č��R����	�xsh����0�]�������b۰%�i�-��Ȗd�yQ�����UBS�5�I�cʳ���ǫ�p�W�>�W1�h)�F�Κ�����`WLI���J�;J�,�=�Q�_^P+��Hz uY���~���<�Ե��!�'��������m�y�X�	Y�?��\����|�3�?!��?!�����{���1� r	���m��A�a��?�����/�%���� �ߠ����oP�쿷��ϫ��J�����~��!��φ\�?Q��fD6��=BN ��G��W�a�7P�:.�������OS���SF���������\Y���ς��?ԅ@DV��}��?d���P��vɅ�G^����L@i�ARz���m�/�_��� �����t��������?���� ������������.z���m�/����ȉ�C]D��������?��g���P��?����R��2��:6��#��۶�r��̕���	���GE.���G��C�?���.���H����[��0��t����_��H]����CF�B���(��K��Ռ2C��\�ʴ��6��%�4��IgX�^֒-,c�e�/r$�~�����Ƀ��K��������)��-����/��*4Ŧ,�r�ɔ��eIzzW�L�Z:6���wژܩ[$+�q M����4��7h��UhGl�#;ړ����	�t���Z�M��@���3[;�j��Z�9WrOp=M�kVo���V�8��[�����d�F{P^�_u>�{���sF����T���Y�<����?t�A�!�(��������n�<�?��������MZ��zzLLD��F!.f0�[����%~Ֆ;{����Ѫ=o���n^���6j2ذ���G�u�T�ow|�^4�m��UM���c$��ۥ:v�9���x�B�T�I����|��E�E������glԿ�����/d@��A��������DH.�?�����`�e�7��=����_�eGA�mO�Y��#W�>o�t�_m����ϧXk�L�|}%~e���۰��m�b�덻,I���,:���7��Ѽ���_�ø0��qaˇ�5�N�/'&�W�l:R����Z��E���*��q:l���+�)0g���~�5̫�G[�?���&;�jM���4�x*��a=��+£-88'(qb����ͪZ��6�K�{a�)��W��@	�S��.Eue���[eZc��`a6��T���0-EU	Sj�c!�@H���:�fi���˻��mC&�v��	��Oo�$��B�'T�u���{�,��o���W�?�"�dA.�����Ń�gAf����e�?�����Z�i���gy�?�����n����O]����L@��/G���?�?r�g��@�o&�I��
d�d���[�1�� �����P��?�.����+�`�er�V�D
���m��B�a�d�F�a�G$����.�)��Ȅo�����s�����A�q|lU�ބ�[�E��6�6�Èkݧ���}��H+�?���z��H?�3�i�����IS>�����~��7����v�Nԯw�U��;N��B�e+sf�o����ސ�>��ٙ9���	�F7�З��0c��d�O�MM��WGi�/�G�~��~�+y��^=mQ lGZrAx>�do+(��X����b,(��Ih`��~gbW���S��p�Q�����jҖ��M�:�7�al`��M���ɰ[�(b!��Y����}+K�!����Q���0ȅ����@n��Xu[�"��߶�����d�I�_�(@�����R�����L��_P��A�/��?�?�@n�}^uS�$��߶���gI�D�H��� oM.���GƷ��J%��Q�Qݎ�F}	ǕK#�e���O5�_�������Dkolzkc3:>�)�^ ��˧��>����c�t܆F/%���{�:���~SѦ-z���b�	L��^���i�[4��A�C������7�e�|q����I & K� ~/�qOP�qc]X���Хa_���)s��ͷ�(��ZX޻�=Yֻ�"�ayӒ�C����
{M�,b���s\A�&T����w��0����+�@��L@n�}ZuK�&��߶���/RW�?A�� ?�ϔ�Њ�eq���K�9/�:m���1:��M����R�Ej<iY�a�<g�K<=縏�[ݿ?3y��k�B�6���?���;�[��3�?a#�<��F-G�~8��ڪ���Ө\x^��X8z�h���Z5��"���Z�1y�*�·������*w*9tayv��9���|\'f�jY��%�C.����|-y����':����"P����C��:r��������`��n��$��:~���w��bY�;�*s�+F/Ŗ�o=D�ݝ�;Qw���q}��n��-��~�i<�\fMH1������;!�#^��b~l��]�!�U3j˺��<�#:k/�xZ��������|���_,�@����C�����/��B�A��A������r�l@4���c�"�����7N�?[�l�=,����E�r9��[ҽ����O9 ?���c9 ��B /s 
+;�i�*m5�[��/�V����NӍբf��-*1��؊(�Y���ן�Ŧ�V�ub���ᇪ^�J�Bk��KI\��4���5!�w��<��Z�F<��.��`(�aM�����ص������	{��K%ٍ��Z�*�Nȶ��p"p����d���7�D)9O$7�j6Q׆�~iHO���m���"�U�@��"Q��4���͖/?�O��]r*=�k{vlYˋ��x��5��(GnO���ƈVz�>�����Q�i����߭�/�<}�����u}�7��d�����tw��8w����?3�"�{��?�����M���"�&�=E�(��aP��3�`���Cz�;?�,gm��ӝ�>�
r�1��w�.�w����~���������t��QZh�k��%fr�O^�8�1�c���J����|>�o�k���)�j�[����}�7��(��*����4�����o�E�K�Z�����Ճឋ[NF�^�O�7µ�:}b6�;�Ќ�;s���bF��lN#'}�LL�I��ٹ�&����#ˁ����č]����N���G���>�{�ܘ��d��߽�E������'U����_�������q?�'���b�o�%9���>=����ߧ���DER8o�����/��?n���b�f��w���c-iW����7��9�� ??Nx��OW���Zrx�:7}�ǋD����:���y>}�ĝ0ܙ������ǁҬ����^kA�I�n����`������\��W,\����[��;��K|���5'�`�o�y�6��������q>ĝ�_�O�d"�_s�܄��s��=�5�OOV���N)i�q��U�%7���U?v����f�#�[5E~��.N"M`؅�h��.����޽�a�����__�S7��������M�Q                           �%�*X�3 � 